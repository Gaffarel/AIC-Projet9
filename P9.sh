#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V0.13a     ##
##                                                                 ##
#####################################################################


#################### Emplacement des programmes #####################

DOCKER="/usr/bin/docker"
DOCKER_COMPOSE="/usr/local/bin/docker-compose"
TAR="/usr/bin/tar"
FTP="/usr/bin/ftp"
#SSH="/usr/bin/ssh"
#SCP="/usr/bin/scp"

#################### Fichier de configuration #######################

#source = P9_config.ini

########################## les variables ############################

SERVEUR_FTP="192.168.0.2"
USER_FTP="allouis"
MDP_FTP="bob"
PORT_FTP=21
BACKUP='/home/backup'
BACKUPDATE=$(date +%Y-%m-%d)
[ ! -d $BACKUP ] && mkdir $BACKUP && chown 0.0 $BACKUP && chmod 600 $BACKUP
contenaire_wordpress=''
contenaire_mariadb=''

############################## SSH ##################################



########################### LES FONCTIONS ###########################

##################### FONCTION N° de Contenaire #####################
function CONTAINER
{
info=$($DOCKER ps | awk 'NR==2{print$1,$2}')
if [[ $info =~ wordpress ]] ; then
    contenaire_wordpress=$($DOCKER ps | awk 'NR==2{print$1}')
    contenaire_mariadb=$($DOCKER ps | awk 'NR==3{print$1}')
elif
    [[ $info =~ mariadb ]] ; then
    contenaire_wordpress=$($DOCKER ps | awk 'NR==3{print$1}')
    contenaire_mariadb=$($DOCKER ps | awk 'NR==2{print$1}')
fi
}

########################### FONCTION FTP ############################

function save_ftp
{
cd $BACKUP
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX
     quote USER $USER_FTP
     quote PASS $MDP_FTP
     pwd
     bin
     cd sauvegarde
     put save_$BACKUPDATE.tar.bz2
     put docker-compose.yml
     quit
FTP_CONNEX
}

function rest_ftp
{
cd $BACKUP
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX
     quote USER $USER_FTP
     quote PASS $MDP_FTP
     pwd
     bin
     cd Projet9/AIC-Projet9
     get P9.sh
     cd /
     cd sauvegarde
     get save_$BACKUPDATE.tar.bz2
     get docker-compose.yml
     quit
FTP_CONNEX
}

####################### Test argument null ##########################

if [[ $# -eq 0 ]] ; then
    echo 'Manque un argument save ou rest'
    exit 1
fi

##################### test argument rest ou save ####################

if  [ "$1" != "rest" ] && [ "$1" != "save" ] ; then
    echo 'Mauvais argument !'
    exit 1
fi

############################ Sauvegarde #############################

if [ "$1" = "save" ] ; then
    CONTAINER
	echo "Sauvegarde en cours ..."
    echo " Sauvegarde de la BDD MariaDB ...";
    sleep 2
    cd $BACKUP
    $DOCKER exec $contenaire_mariadb /usr/bin/mysqldump -u allouis --password=bob MyCompany > db_$BACKUPDATE.sql
    echo "  Sauvegarde des Volumes Docker et des paramètres du réseau ......";
    sleep 2
    cd /
    $TAR cvpjf $BACKUP/save_$BACKUPDATE.tar.bz2 var/lib/docker/volumes/ etc/network/interfaces etc/resolv.conf etc/hosts etc/hostname var/log/ tmp/testlog/ home/backup/docker-compose.yml home/backup/db_$BACKUPDATE.sql
    echo "   Transfert vers le serveur FTP ...";
    sleep 2
    save_ftp

########################### Restauration ############################

elif [ "$1" = "rest" ] ; then

echo "Procédure de récupération en cours ..."

########################### Docker Engine ###########################
echo " Préparation à l'installation de docker ..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update
echo " Installation de docker-Engine ..."
apt-get install -y docker-ce docker-ce-cli containerd.io

########################## DOCKER-COMPOSE ###########################
echo " Installation de docker-Compose ..."
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

docker-compose --version
sleep 5

################### Restauration des Images Docker ##################

cd $BACKUP

DOCKER_COMPOSE up -d

#### Restauration des Volumes Docker et des paramètres du réseau ####

CONTAINER
echo "  Restauration de la BDD MariaDB ..."
cat db_$BACKUPDATE.sql | docker exec -i $contenaire_mariadb /usr/bin/mysql -u allouis --password=bob MyCompany

########## Restauration des fichier docker et de la BDD ############

echo "Restauration des Volumes Docker et des paramètres du réseau ......";
tar xvpjf save_$BACKUPDATE.tar.bz2 -C /
fi


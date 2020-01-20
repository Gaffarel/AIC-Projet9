#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V0.12e     ##
##                                                                 ##
#####################################################################


#################### Emplacement des programmes #####################

DOCKER="/usr/bin/docker"
TAR="/usr/bin/tar"
SCP="/usr/bin/scp"
FTP="/usr/bin/ftp"
#SSH="/usr/bin/ssh"

########################## les variables ############################

SERVEUR_FTP='192.168.0.2'
BACKUP='/home/backup'
BACKUPDATE=$(date +%Y-%m-%d)
#[ ! -d $BACKUP ] && mkdir $BACKUP && chown 0.0 $BACKUP && chmod 600 $BACKUP
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

#################### Fichier de configuration #######################

#source = P9_config.ini

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
    $DOCKER exec $contenaire_mariadb /usr/bin/mysqldump -u allouis --password=bob MyCompany > db.sql
    echo "  Sauvegarde des Volumes Docker ...";
    sleep 2
    $TAR cvpjf save_$BACKUPDATE.tar.bz2 var/lib/docker/volumes/
    echo "   Sauvegarde des paramètres du réseau ...";
    sleep 2
    $TAR rf save_$BACKUPDATE.tar.bz2 etc/network/interfaces etc/resolv.conf etc/hosts etc/hostname


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

###################### Restauration de la BDD #######################

echo "  Restauration de la BDD MariaDB ..."
#cat db.sql | docker exec -i 840 /usr/bin/mysql -u allouis --password=bob MyCompany


fi


#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V0.25      ##
##                                                                 ##
#####################################################################


#################### Emplacement des programmes #####################

DOCKER="/usr/bin/docker"
TAR="/usr/bin/tar"
CAT="/usr/bin/cat"
FTP="/usr/bin/ftp"

#################### Fichier de configuration #######################

source /home/backup/P9_config.ini

########################## les variables ############################

BACKUPDATE=$(date +%Y-%m-%d)
BACKUPDATE_OLD=$(date +%Y-%m-%d --date="$NBjour days ago")
[ ! -d $BACKUP ] && mkdir $BACKUP && chown 0.0 $BACKUP && chmod 600 $BACKUP
contenaire_wordpress=''
contenaire_mariadb=''

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
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX
     quote USER $USER_FTP
     quote PASS $MDP_FTP
     bin
     cd sauvegarde
     delete save_$BACKUPDATE_OLD.tar.bz2
     put save_$BACKUPDATE.tar.bz2
     put db_$BACKUPDATE.sql
     put docker-compose.yml
     ls save_*.tar.bz2 save_liste.txt
     quit
FTP_CONNEX
}

function rest_ftp
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX
     quote USER $USER_FTP
     quote PASS $MDP_FTP
     bin
     cd sauvegarde
     get save_$BACKUPDATE.tar.bz2
     get db_$BACKUPDATE.sql
     get docker-compose.yml
     get .env
     get P9_config.ini
     ls save_*.tar.bz2 save_liste.txt
     quit
FTP_CONNEX
}

####################### Test argument null ##########################

if [[ $# -eq 0 ]] ; then
    echo 'Manque un argument save / rest / docker '
    echo 'Pour sauvegarder votre serveur Wordpress et la BDD MariaDB: P9.sh save '
    echo 'Pour installer DOCKER: P9.sh docker '
    echo 'Pour restaurer votre serveur Wordpress: P9.sh rest '
    exit 1
fi

##################### test argument rest ou save ####################

if  [ "$1" != "rest" ] && [ "$1" != "save" ] && [ "$1" != "docker" ] ; then
    echo 'Mauvais argument !'
    echo 'Pour sauvegarder votre serveur Wordpress et la BDD MariaDB: P9.sh save '
    echo 'Pour installer DOCKER: P9.sh docker '
    echo 'Pour restaurer votre serveur Wordpress: P9.sh rest '
    exit 1
fi

#####################################################################
############################ Sauvegarde #############################
#####################################################################

if [ "$1" = "save" ] ; then
    CONTAINER
	echo "Sauvegarde en cours ..."
    echo " Sauvegarde de la BDD MariaDB ...";
    sleep 2
    $DOCKER exec $contenaire_mariadb /usr/bin/mysqldump -u $USER_BDD --password=$MDP_BDD MyCompany > $BACKUP/db_$BACKUPDATE.sql
    echo "  Sauvegarde des Volumes Docker et des paramètres du réseau ......";
    sleep 2
    $TAR cvpjf $BACKUP/save_$BACKUPDATE.tar.bz2 /var/lib/docker/volumes/backup_wp/ /etc/network/interfaces /etc/resolv.conf /etc/hosts /etc/hostname /var/spool/cron/crontabs/ /var/log/ $BACKUP/log/ $BACKUP/docker-compose.yml
    echo "   Transfert vers le serveur FTP ...";
    sleep 2
    save_ftp
    rm -f $BACKUP/db_$BACKUPDATE.sql
    rm -f $BACKUP/save_$BACKUPDATE.tar.bz2

#####################################################################
##################### Installation de DOCKER ########################
#####################################################################

elif [ "$1" = "docker" ] ; then

########################### Docker Engine ###########################

echo " Préparation à l'installation de docker ..."
sleep 2
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
sleep 2
apt-get install -y docker-ce docker-ce-cli containerd.io

########################## DOCKER-COMPOSE ###########################

echo " Installation de docker-Compose ..."
sleep 2
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

docker-compose --version
sleep 5

#####################################################################
########################### Restauration ############################
#####################################################################

elif [ "$1" = "rest" ] ; then

################### Restauration des Images Docker ##################

rest_ftp
docker-compose up -d
sleep 2
## Restauration des Volumes Wordpress et des paramètres du réseau ###

echo "Restauration des Volumes Docker et des paramètres du réseau ......";
$TAR xvpjf $BACKUP/save_$BACKUPDATE.tar.bz2 -C /
sleep 2
################## Restauration de la BDD MariaDB ###################

CONTAINER
echo "Restauration de la BDD MariaDB ..."
$CAT $BACKUP/db_$BACKUPDATE.sql | docker exec -i $contenaire_mariadb /usr/bin/mysql -u $USER_BDD --password=$MDP_BDD MyCompany
sleep 5
#reboot

fi

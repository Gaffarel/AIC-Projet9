#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V0.12a     ##
##                                                                 ##
#####################################################################


########################## les variables ############################

SERVEUR_FTP='192.168.0.2'
BACKUP='/home/backup'
BACKUPDATE=$(date +%Y-%m-%d)
#[ ! -d $BACKUP ] && mkdir $BACKUP && chown 0.0 $BACKUP && chmod 600 $BACKUP

############################## SSH ##################################



#################### Emplacement des programmes #####################

TAR="/bin/tar"
SCP="/usr/bin/scp"
SSH="/usr/bin/ssh"

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

	echo "Sauvegarde en cours ..."
    echo " Sauvegarde des paramètres du réseau ..."
    tar cvpjf save_res.tar.bz2 etc/network/interfaces etc/resolv.conf etc/hosts etc/hostname
    echo "  Sauvegarde de la BDD MariaDB ..."
    #docker exec 840 /usr/bin/mysqldump -u allouis --password=bob MyCompany > db.sql
    echo "   Sauvegarde des paramètres du réseau ..."

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


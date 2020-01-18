#!/bin/bash
########################## les variables ############################

SERVEUR_FTP='192.168.0.2'
BACKUP='/home/backup'
BACKUPDATE=$(date +%Y-%m-%d)
[ ! -d $BACKUP ] && mkdir $BACKUP && chown 0.0 $BACKUP && chmod 600 $BACKUP


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
    tar cvpjf save_res.tar.bz2 etc/network/interface etc/resolv.conf etc/hosts etc/hostname
    echo "  Sauvegarde de la BDD MariaDB ..."
    #docker exec 840 /usr/bin/mysqldump -u allouis --password=bob MyCompany > db.sql
    echo "   Sauvegarde des paramètres du réseau ..."

#####################################################################

elif [ "$1" = "rest" ] ; then
echo "Procédure de récupération en cours ..."

fi


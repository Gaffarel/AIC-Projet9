#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V1.0       ##
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
choix=''

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
     bin
     cd sauvegarde
     delete save_$BACKUPDATE_OLD.tar.bz2
     delete db_$BACKUPDATE_OLD.sql
     put save_$BACKUPDATE.tar.bz2
     put db_$BACKUPDATE.sql
     quit
FTP_CONNEX
}

function rest_ftp
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX1
     quote USER $USER_FTP
     quote PASS $MDP_FTP
     bin
     cd sauvegarde
     get docker-compose.yml
     get .env
     quit
FTP_CONNEX1
}

function list_ftp
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX2
	quote USER $USER_FTP
	quote PASS $MDP_FTP
	bin
	cd sauvegarde
	ls db_*.sql save_db.txt
	ls save_*.tar.bz2 save_liste.txt
	quit
FTP_CONNEX2
}

function recup_ftp1
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX3
	quote USER $USER_FTP
	quote PASS $MDP_FTP
	bin
	cd sauvegarde
	get $choix
	quit
FTP_CONNEX3
}

function recup_ftp2
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX4
	quote USER $USER_FTP
	quote PASS $MDP_FTP
	bin
	cd sauvegarde
	get $choix_db
	quit
FTP_CONNEX4
}

####################### Test argument null ##########################

if [[ $# -eq 0 ]] ; then
    echo 'Manque un argument save / rest / docker '
    echo 'Pour sauvegarder votre serveur Wordpress et la BDD MariaDB: P9.sh save '
    echo 'Pour installer DOCKER: P9.sh docker '
    echo 'Pour restaurer votre serveur Wordpress en entier: P9.sh rest '
    echo 'Pour restaurer votre BDD à une date précise du serveur Wordpress: P9.sh rest_db '
    exit 1
fi

##################### test argument rest ou save ####################

if  [ "$1" != "rest" ] && [ "$1" != "save" ] && [ "$1" != "docker" ] && [ "$1" != "rest_db" ] ; then
    echo 'Mauvais argument !'
    echo 'Pour sauvegarder votre serveur Wordpress et la BDD MariaDB: P9.sh save '
    echo 'Pour installer DOCKER: P9.sh docker '
    echo 'Pour restaurer votre serveur Wordpress: P9.sh rest '
    echo 'Pour restaurer votre BDD à une date précise du serveur Wordpress: P9.sh rest_db '
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
sleep 2

################### Restauration des Images Docker ##################

rest_ftp
docker-compose up -d
sleep 2

#####################################################################
####################### Restauration Totale #########################
#####################################################################

elif [ "$1" = "rest" ] ; then

list_ftp

echo "Qual Sauvegarde voulez-vous restaurer ?"
fic=$( $CAT 'save_liste.txt' | awk '{print $9}')
select choix in $(echo "$fic") ;
	do echo "Mon choix est $choix :";
	break;
done

recup_ftp1

## Restauration des Volumes Wordpress et des paramètres du réseau ###

echo "Restauration des Volumes Docker et des paramètres du réseau ......";
$TAR xvpjf $BACKUP/$choix -C /
sleep 2
################## Restauration de la BDD MariaDB ###################

#choix_db=$(db_$choix | cut -c3-11 )
#ip=$(sudo ifconfig enp0s3 | grep 'inet 192.168.' | awk '{print $2}' | cut -c9-11)

CONTAINER

echo "Restauration de la BDD ok ..."
$CAT $BACKUP/db_*.sql | docker exec -i $contenaire_mariadb /usr/bin/mysql -u $USER_BDD -p$MDP_BDD MyCompany
sleep 2

#rm -f $BACKUP/db_*.sql
#rm -f $BACKUP/save_*.tar.bz2

#reboot

#####################################################################
######################### Restauration BDD ##########################
#####################################################################


elif [ "$1" = "rest_db" ] ; then

list_ftp

echo "Restauration de la BDD MariaDB ..."
fic=$( $CAT 'save_db.txt' | awk '{print $9}')
select choix_db in $(echo "$fic") ;
	do echo "Mon choix est $choix_db :";
	break;
done

recup_ftp2

CONTAINER

echo "Restauration de la BDD ok ..."
$CAT $BACKUP/$choix_db | docker exec -i $contenaire_mariadb /usr/bin/mysql -u $USER_BDD -p$MDP_BDD MyCompany
sleep 2

#rm -f $BACKUP/db_*.sql

#reboot - non utile !

fi
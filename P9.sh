#!/bin/bash

#####################################################################
##                                                                 ##
##     Script de sauvegarde et restauration wordpresss  V1.0e      ##
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

### Suppression des anciennes sauvegardes et dépôts des nouvelles ###

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

### Récupération des fichiers de configuration pour docker-compose ####

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

### Récupération de la liste des sauvegardes sans un fichier .TXT ###

function list_ftp
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX2
	quote USER $USER_FTP
	quote PASS $MDP_FTP
	bin
	cd sauvegarde
	ls save_*.tar.bz2 save_liste.txt
	quit
FTP_CONNEX2
}

##### Récuperation de la sauvegarde sélectionnées dans la liste #####

function recup_ftp
{
   ftp -i -n $SERVEUR_FTP $PORT_FTP <<FTP_CONNEX3
	quote USER $USER_FTP
	quote PASS $MDP_FTP
	bin
	cd sauvegarde
	get $choix
    get $choix_db
	quit
FTP_CONNEX3
}

####################### Test argument null ##########################

if [[ $# -eq 0 ]] ; then
    echo 'Manque un argument save / rest / rest_db / docker '
    echo 'Pour sauvegarder votre serveur Wordpress et la BDD MariaDB: P9.sh save '
    echo 'Pour installer DOCKER: P9.sh docker '
    echo 'Pour restaurer votre serveur Wordpress en entier: P9.sh rest '
    echo 'Pour restaurer votre BDD à une date précise du serveur Wordpress: P9.sh rest_db '
    exit 1
fi

############ Test argument rest / save / docker / res_db ############

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
    $DOCKER exec $contenaire_mariadb /usr/bin/mysqldump -u $USER_BDD --password=$MDP_BDD MyCompany > $BACKUP/db_$BACKUPDATE.sql
    $TAR cvpjf $BACKUP/save_$BACKUPDATE.tar.bz2 /var/lib/docker/volumes/backup_wp/ /etc/network/interfaces /etc/resolv.conf /etc/hosts /etc/hostname /var/spool/cron/crontabs/ /var/log/ $BACKUP/log/ $BACKUP/docker-compose.yml
    save_ftp
################## Suppression des fichiers créer ###################
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

############# Récupération de la liste des sauvegardes ##############

list_ftp

################ Liste de selection des sauvegardes #################

echo "Quelle Sauvegarde voulez-vous restaurer ?"
fic=$( $CAT 'save_liste.txt' | awk '{print $9}')
select choix in $(echo "$fic") ;
	do echo "Mon choix est : $choix";
	break;
done

choix_db="db_$(echo "$choix" | cut -c6-15 ).sql"

recup_ftp

## Restauration des Volumes Wordpress et des paramètres du réseau ###

echo "Restauration des Volumes Docker et des paramètres du réseau ... "
sleep 2
$TAR xvpjf $BACKUP/$choix -C /

################## Restauration de la BDD MariaDB ###################

CONTAINER

echo "Restauration de la BDD ... "
sleep 2
$CAT $BACKUP/$choix_db | docker exec -i $contenaire_mariadb /usr/bin/mysql -u $USER_BDD -p$MDP_BDD MyCompany
################## Suppression des fichiers créer ###################
rm -f $BACKUP/$choix_db
rm -f $BACKUP/$choix

echo "Reboot dans 5 secondes ... "
sleep 5

reboot

#####################################################################
######################### Restauration BDD ##########################
#####################################################################


elif [ "$1" = "rest_db" ] ; then

############# Récupération de la liste des sauvegardes ##############

list_ftp

################ Liste de selection des sauvegardes #################

fic=$( $CAT 'save_liste.txt' | awk '{print $9}')
select choix in $(echo "$fic") ;
	do echo "Mon choix est : $choix";
	break;
done

choix_db="db_$(echo "$choix" | cut -c6-15 ).sql"

recup_ftp

################## Restauration de la BDD MariaDB ###################

CONTAINER

$CAT $BACKUP/$choix_db | docker exec -i $contenaire_mariadb /usr/bin/mysql -u $USER_BDD -p$MDP_BDD MyCompany
echo "Restauration de la BDD ok ..."
################## Suppression des fichiers créer ###################
rm -f $BACKUP/$choix_db
rm -f $BACKUP/$choix

fi
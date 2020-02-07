# <div align="center"> Script de sauvegarde et de restauration d'un serveur Wordpress et MariaDB sous Docker </div>

## <div align="center"> Projet N°9 [AIC] </div>

## Mise en place :

dans mon projet le serveur FTP donne l'accès directement à un dossier où se trouve un repertoire sauvegarde  
dans lequel se trouve les fichiers :  

- docker-compose.yml
- env

* Etape N°1:  

Créer le dossier backup dans /home sous root

MKDIR /HOME/BACKUP

* Etape N°2:

Récupérer ou créer le fichier P9_config.ini et le mettre dans /home/backup

* Etape N°3:

Récupérer ou créer le fichier d'environnement .env et le mettre dans /home/backup

* Etape N°4:

Récupérer le fichier docker-compose.yml et le mettre dans /home/backup

* Etape N°5:

Installer le client FTP  
apt-get install ftp  

## PROCEDURE:

### Pour sauvegarder votre serveur Wordpress et sa Base De Donnée MariaDB:

P9.sh save

### Pour installer DOCKER-CE et DOCKER-COMPOSE et installer les images Wordpress et MariaDB:

P9.sh docker

### Pour restaurer l'intégralite du serveur Wordpress à une date donnée:

P9.sh rest

### Pour restaurer uniquement votre base de donnée Mysql MariaDB à une date donnée:

P9.sh rest_db

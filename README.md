# <div align="center"> Script de sauvegarde et de restauration d'un serveur Wordpress et MariaDB sous Docker </div>

## <div align="center"> Projet N°9 [AIC] </div>

* Etape N°1:  

Créer le dossier backup dans /home

MKDIR /HOME/BACKUP

* Etape N°2:

Récupérer ou créer le fichier P9_config.ini et le mettre dans /home/backup

## fichier de config de P9.sh

| SERVEUR_FTP="O.O.O.O" |: -> adresse ip du serveur FTP                           :|  
| USER_FTP="XXXXXX"     |: -> utilisateur authorisé à ce connecter au serveur FTP :|  
| MDP_FTP="YYYYYY"      |: -> Mot de passe de l'utilisateur FTP                   :|  
| USER_BDD="ZZZZZZ"     |:                                                        :|  
| MDP_BDD="AAAAAA"      |:                                                        :|  
| PORT_FTP=21           |:                                                        :|  
| NBjour=30             |:                                                        :|  
| BACKUP='/home/backup' |:                                                        :|  

* Etape N°3:

Récupérer ou créer le fichier d'environnement .env et le mettre dans /home/backup

## fichier de configuration pour docker-compose.yml

DB_ROOT_PASSWORD=BBBBBB  
DB_DATABASE=MyCompany  
DB_USER=ZZZZZZ  
DB_PASSWORD=AAAAAA  
WP_DB_USER=ZZZZZZ  
WP_DB_PASSWORD=AAAAAA  
WP_DB_NAME=MyCompany  

* Etape N°4:

Récupérer le fichier docker-compose.yml et le mettre dans /home/backup

## PROCEDURE:

### Pour sauvegarder votre serveur Wordpress et sa Base De Donnée MariaDB:

P9.sh save

### Pour installer DOCKER-CE et DOCKER-COMPOSE et installer les images Wordpress et MariaDB:

P9.sh docker

### Pour restaurer l'intégralite du serveur Wordpress à une date donnée:

P9.sh rest

### Pour restaurer uniquement votre base de donnée Mysql MariaDB à une date donnée:

P9.sh rest_db

#!/bin/bash


echo "Quel est votre choix ?"
echo
echo "1) Installation du client FTP "
echo "2) Installation de la clé publique du <<serveur-routeur>> "
echo "3) Ajouter l'utilisateur stagiaire "
echo "4) Supprimer l'utilisateur Stagiaire "
echo "5) Changement du NOM de le machine "
echo "6) Paramétrage du partage de dossier Abeille ou Baobab "
echo "7) Raccourcis sur le burau du stagiaire Abeille ou Baobab "
echo "8) Script Automatique étape 4/5/3/6/7"
echo "9) Quitter"
echo

read choix

case $choix in
	1)
	sudo apt-get install ftp 
	;;
	2)
	;;
	3)
	;;
	4)
	;;
	5)
	;;
	6)
	;;
	7)
	;;
	8)
	;;
	9)
	exit
	;;
esac
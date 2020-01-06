#!/bin/bash

# Constante du Serveur FTP

SERVEUR='192.168.0.221'
LOGIN='allouis'
MDP='bob'
PORT='21'

# Transfert vers VSFTPD

ftp -n $SERVEUR $PORT <<END_SCRIPT
quote USER $LOGIN
quote PASS $MDP
bin
cd/sauvegarde
put liste-des-paquets1
quit
END_SCRIPT

exit 0

##################################################################

function Televerse(){
  SITFTP="ftp.adresse.caca"
  USAFTP="usager@adresse.caca"
  MPSFTP="MotDePasse"
  PRTFTP=21
  source plongee.cnf

ftp -i -n $SITFTP $PRTFTP <<END_SCRIPT
quote USER $USAFTP
quote PASS $MPSFTP
bin
put plongee.cnf $1.log
cd Contenu
put $2
quit
END_SCRIPT
}

#blabalabala

FUNC=$(declare -f Televerse)
sudo bash -c "$FUNC; Televerse $variable1 $variable2"

#Le code se poursuit

#####################################################################

#Autre code avant

function Televerse(){
  SITFTP="ftp.adresse.qc"
  USAFTP="identifiant@adresse.qc"
  MPSFTP="MotDePasse"
  PRTFTP=21
  source fichierSource.cnf

  ftp -i -n $SITFTP $PRTFTP <<FTP_CONNEX
    quote USER $USAFTP
    quote PASS $MPSFTP
    bin
    put plongee.cnf $1.log
    cd Contenu
    put $2
    quit
FTP_CONNEX
}

#Autre code après

#Appel du script
  FUNC=$(declare -f Televerse)
  sudo bash -c "$FUNC; Televerse $variable1 $variable2"

#.... vers la fin du fichier

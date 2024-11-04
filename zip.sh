#!/bin/sh
#Batch qui copie le contenu de SOURCE_DIR vers RESULT_DIR, en ne conservant que le log Apache, et en anonymisant les IPs (XXX.XXX.0.0) et les eventuelles adresses mails

SOURCE_DIR="/home/node/logstash"
RESULT_DIR="/home/node/logtheses/logs/data/thesesfr/logs"
CAT_COMMAND="cat"

if [[ $(ps -edf | grep -c "zip.sh") = 3 ]];then
  #On prend les fichiers qui ont plus de 7 jours : car logstash ecrit parfois dans les fichiers apres la date du jour
  for SOURCE_FILE in $(find $SOURCE_DIR/*/*/logstash-* -type f -mtime +7)
  do
          #Replace du chemin SOURCE par le chemin RESULT
          #Les @ servent a la place de / , car on a des / dans les valeurs a remplacer
          #Exemple :
          #/home/node/logstash/2024/04/logstash-appli-theses-rp-2024.04.25.gz sera remplace en :
          #/home/node/logtheses/logs/data/thesesfr/logs/2024/04/logstash-appli-theses-rp-2024.04.25.gz.log.gz
                          #Voir : https://stackoverflow.com/questions/3306007/replace-a-string-in-shell-script-using-a-variable

          FichierResultat=$(echo $SOURCE_FILE | sed -e "s@$SOURCE_DIR@$RESULT_DIR@g")

          #Si le fichier est zippe, il faudra utiliser zcat
          if [[ "$FichierResultat" == *"gz"* ]] ;then
            CAT_COMMAND="zcat"
          else
            CAT_COMMAND="cat"
          fi

          #Recuperation du repertoire $RepertoireResultat
                          #Voir : https://stackoverflow.com/questions/3294072/get-last-dirname-filename-in-a-file-path-argument-in-bash

          RepertoireResultat=$(dirname $FichierResultat)

          #Si le repertoire $RepertoireResultat n'existe pas, on le cree
          if [ ! -d $RepertoireResultat ]; then
            mkdir -p $RepertoireResultat
          fi

          if [ ! -f ${FichierResultat}.log.gz ]; then
            dt=$(date '+%d/%m/%Y %H:%M:%S')
            echo "$dt traitement du fichier : ${FichierResultat}.log.gz"

            #grep -E "^[0-9]{1,3}\." : On ne conserve que les lignes commencants par 3 chiffres (debut d'adresse IP). Pas les lignes RENATER_SP ou les erreurs Proxy
            #grep -v "UptimeRobot" : On ne conserve pas les lignes contenants UptimeRobot
            #sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' : anonymisation des IPS (2 derniers chiffres passes à 0.0)
            #sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' : anonymisation des logins Shibboleth (adresse mail supprimee)

            ${CAT_COMMAND} ${SOURCE_FILE} | \
            jq -r 'select(.container.name == "theses-rp") | .message' | \
            grep -E "^[0-9]{1,3}\." | \
            grep -v "UptimeRobot" | \
            sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' | \
            sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' | \
            gzip \
            > "${FichierResultat}.log.gz"
          fi

  done
else
  dt=$(date '+%d/%m/%Y %H:%M:%S')
  echo "$dt zip.sh s'execute deja"
fi
#!/bin/sh
#Batch qui copie le contenu de SOURCE_DIR vers RESULT_DIR, en ne conservant que le log Apache, et en anonymisant les IPs (XXX.XXX.0.0) et les eventuelles adresses mails

SOURCE_DIR="/home/node/logstash"
RESULT_DIR="/home/node/logtheses/logs/data/thesesfr/logs"
CAT_COMMAND="cat"

for SOURCE_FILE in $(ls $SOURCE_DIR/*/*/logstash-*)
do
        #Replace du chemin SOURCE par le chemin RESULT
        #Les @ servent a la place de / , car on a des / dans les valeurs a remplacer
        #Exemple :
        #/home/node/logstash/2024/04/logstash-appli-theses-rp-2024.04.25 sera remplace en :
        #/home/node/logtheses/logs/data/thesesfr/logs/2024/04/logstash-appli-theses-rp-2024.04.25
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

        if [ ! -f ${FichierResultat}.log ]; then
          echo "traitement du fichier : ${FichierResultat}.log"

          #grep -v -E "^20[0-9]{2}-[0-9]{2}-[0-9]{2}|^\[" : Suppression des logs SAML et des logs d'erreurs Proxy
          #sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' : anonymisation des IPS (2 derniers chiffres passés à 0.0)
          #sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' : anonymisation des logins Shibboleth (adresse mail supprimée)

          ${CAT_COMMAND} ${SOURCE_FILE} | \
          jq -r 'select(.container.name == "theses-rp") | .event.original' | \
          grep -v -E "^20[0-9]{2}-[0-9]{2}-[0-9]{2}|^\[" | \
          sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' | \
          sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' \
          > "${FichierResultat}.log"
        fi

done
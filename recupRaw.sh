#!/bin/sh
#Batch qui copie le contenu de SOURCE_DIR vers RESULT_DIR, en ne conservant que le log Apache, et en anonymisant les IPs (XXX.XXX.0.0) et les eventuelles adresses mails

# !! Ne sert que pour traiter les quelques fichiers de 2024/03 qui ne sont pas en JSON.

SOURCE_DIR="/home/node/logstash"
RESULT_DIR="/home/node/logtheses/logs/data/thesesfr/logs"

for SOURCE_FILE in $(ls $SOURCE_DIR/2024/03/logstash-*.raw.gz)
do
        FichierResultat=$(echo $SOURCE_FILE | sed -e "s@$SOURCE_DIR@$RESULT_DIR@g")

        RepertoireResultat=$(dirname $FichierResultat)

        echo "traitement du fichier : ${FichierResultat}.log.gz"

        #grep -E "^\"[0-9]{1,3}\." : On ne conserve que les lignes commencants par 3 chiffres (debut d'adresse IP). Pas les lignes RENATER_SP ou les erreurs Proxy
        #sed -E 's/\\"/"/g; s/.$//; s/^.//' : Unescape
        #grep -v "UptimeRobot" : On ne conserve pas les lignes contenants UptimeRobot
        #sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' : anonymisation des IPS (2 derniers chiffres passes à 0.0)
        #sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' : anonymisation des logins Shibboleth (adresse mail supprimee)

        zcat ${SOURCE_FILE} | \
        grep -E "^\"[0-9]{1,3}\." | \
        sed -E 's/\\"/"/g; s/.$//; s/^.//' | \
        grep -v "UptimeRobot" | \
        sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' | \
        sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' | \
        gzip \
        > "${FichierResultat}.log.gz"
done
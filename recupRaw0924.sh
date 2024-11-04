#!/bin/sh
#Batch qui copie le contenu de SOURCE_DIR vers RESULT_DIR, en ne conservant que le log Apache, et en anonymisant les IPs (XXX.XXX.0.0) et les eventuelles adresses mails

# !! Ne sert que pour traiter le fichier du 2024/09/31 qui n'est pas en JSON.

SOURCE_DIR="/home/node/logstash"
RESULT_DIR="/home/node/logtheses/logs/data/thesesfr/logs"

# Decoupage du fichier contenant plusieurs jours de logs
zcat $SOURCE_DIR/2024/09/logstash-appli-theses-rp-2024.09.31.raw.gz | awk 'BEGIN {
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ", months, " ")
    for (a = 1; a <= 12; a++)
        m[months[a]] = sprintf("%02d", a)
}
{
    split($4,array,"[:/]")
    year = array[3]
    month = m[array[2]]
    day = substr(array[1],2)

    print | "gzip > /home/node/logtheses/logs/data/thesesfr/logs/2024/09/logstash-appli-theses-rp-"year"."month"."day".raw.gz";
}'


for SOURCE_FILE in $(ls $RESULT_DIR/2024/09/logstash-*.raw.gz)
do
        FichierResultat=$(echo $SOURCE_FILE) # | sed -e "s@$SOURCE_DIR@$RESULT_DIR@g")

        RepertoireResultat=$(dirname $FichierResultat)

        echo "traitement du fichier : ${FichierResultat}.log.gz"

        # grep -E "^\"[0-9]{1,3}\." : On ne conserve que les lignes commencants par 3 chiffres (debut d'adresse IP). Pas les lignes RENATER_SP ou les erreurs Proxy
        # grep -v "UptimeRobot" : On ne conserve pas les lignes contenants UptimeRobot
        # grep -v "_nuxt" : On ne conserve pas les lignes contenants /_nuxt/
        # sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' : anonymisation des IPS (2 derniers chiffres passes à 0.0)
        # sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' : anonymisation des logins Shibboleth (adresse mail supprimee)

        zcat ${SOURCE_FILE} | \
        grep -E "^[0-9]{1,3}\." | \
        grep -v "UptimeRobot" | \
        grep -v "\/_nuxt\/" | \
        sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.0.0/g' | \
        sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b//g' | \
        gzip \
        > "${FichierResultat}.log.gz"

        #Pour ne pas que le fichier raw soit traite par EZPaarse : on le supprime une fois anonymise
        rm $SOURCE_FILE
done

#Changement de repertoire pour les logs d'octobre
mv $RESULT_DIR/2024/09/logstash-appli-theses-rp-2024.10* $RESULT_DIR/2024/10/
FROM alpine:latest as ezstats-batch-logs
RUN apk add --no-cache --update docker openrc jq
RUN rc-update add docker boot

RUN echo "6    0       *       *       *       /zip.sh 1>/proc/1/fd/1 2>/proc/1/fd/2" >> /var/spool/cron/crontabs/root

RUN apk add --no-cache --update tzdata
ENV TZ="Europe/Paris"
COPY ./entrypoint.sh /
COPY ./zip.sh /
COPY ./recupRaw.sh /
RUN chmod +x /entrypoint.sh
RUN chmod +x /zip.sh
RUN chmod +x /recupRaw.sh
ENTRYPOINT ["/entrypoint.sh"]
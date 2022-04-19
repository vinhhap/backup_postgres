FROM postgres:14

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Asia/Ho_Chi_Minh"

ENV POSTGRES_DATABASE=**None**
ENV POSTGRES_BACKUP_ALL=**None**
ENV POSTGRES_HOST=**None**
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=**None**
ENV POSTGRES_PASSWORD=**None**

ENV B2_APP_ID=**None**
ENV B2_APP_KEY=**None**
ENV B2_BUCKET=**None**
ENV B2_BACKUP_PATH=**None**

ENV BACKUP_PATH=/backup
ENV SCHEDULE=**None**

USER root

RUN mkdir $BACKUP_PATH

RUN apt update -y && \
    apt install python3 python3-pip nano curl -y && \
    apt-get autoremove -yqq --purge && \
    apt-get clean

RUN curl -L https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && \
    chmod u+x /usr/local/bin/go-cron

RUN pip install boto3 b2

COPY scripts/run.sh /run.sh
COPY scripts/backup.sh /backup.sh

RUN chmod u+x /run.sh && \
    chmod u+x /backup.sh

CMD ["sh", "-c", "/run.sh"]
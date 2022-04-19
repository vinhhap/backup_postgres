#! /bin/sh

# exit if a command fails
set -e

if [ $B2_APP_ID = "**None**" ]; then
  echo "You need to set the B2_APP_ID environment variable."
  exit 1
fi

if [ $B2_APP_KEY = "**None**" ]; then
  echo "You need to set the B2_APP_KEY environment variable."
  exit 1
fi

if [ $B2_BUCKET = "**None**" ]; then
  echo "You need to set the B2_BUCKET environment variable."
  exit 1
fi

if [ $B2_BACKUP_PATH = "**None**" ]; then
  echo "You need to set the B2_BACKUP_PATH environment variable."
  exit 1
fi

if [ $POSTGRES_DATABASE = "**None**" -a "${POSTGRES_BACKUP_ALL}" != "true" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ $POSTGRES_HOST = "**None**" ]; then
  if [ -n $POSTGRES_PORT_5432_TCP_ADDR ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ $POSTGRES_USER = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ $POSTGRES_PASSWORD = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

# Authorize b2
b2 authorize-account $B2_APP_ID $B2_APP_KEY

export BACKUP_TIME=$(date +"%Y%m%d%H%M%S")

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

if [ $POSTGRES_BACKUP_ALL = "true" ]; then
  echo "Creating dump of all databases from ${POSTGRES_HOST}..."

  pg_dumpall -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER | gzip > "${BACKUP_PATH}/all_${BACKUP_TIME}_dump.sql.gz"

  echo "Uploading dump to Backblaze $B2_BUCKET"

  b2 upload-file $B2_BUCKET "${BACKUP_PATH}/all_${BACKUP_TIME}_dump.sql.gz" "${B2_BACKUP_PATH}/all_${BACKUP_TIME}_dump.sql.gz"

  echo "SQL backup uploaded successfully"

  rm -rf "${BACKUP_PATH}/all_${BACKUP_TIME}_dump.sql.gz"
else
  OIFS="$IFS"
  IFS=','
  for DB in $POSTGRES_DATABASE
  do
    IFS="$OIFS"

    echo "Creating dump of ${DB} database from ${POSTGRES_HOST}..."

    pg_dump $POSTGRES_HOST_OPTS $DB | gzip > "${BACKUP_PATH}/${DB}/${DB}_${BACKUP_TIME}_dump.sql.gz"

    echo "Uploading dump to $S3_BUCKET"
    
    b2 upload-file $B2_BUCKET "${BACKUP_PATH}/${DB}/${DB}_${BACKUP_TIME}_dump.sql.gz" "${BACKUP_PATH}/${DB}/${DB}_${BACKUP_TIME}_dump.sql.gz"

    echo "SQL backup uploaded successfully"

    rm -rf "${BACKUP_PATH}/${DB}/${DB}_${BACKUP_TIME}_dump.sql.gz"
  done
fi
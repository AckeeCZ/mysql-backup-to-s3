#!/bin/bash
set -eo pipefail

# verify variables
if [ -z "$S3_ACCESS_KEY" -o -z "$S3_SECRET_KEY" -o -z "$S3_URL" -o -z "$MYSQL_HOST" -o -z "$MYSQL_PORT" ]; then
	echo >&2 'Backup information is not complete. You need to specify S3_ACCESS_KEY, S3_SECRET_KEY, S3_URL, MYSQL_URL, MYSQL_PORT. No backups, no fun.'
	exit 1
fi

# set s3 config
sed -i "s/%%S3_ACCESS_KEY%%/$S3_ACCESS_KEY/g" /root/.s3cfg
sed -i "s/%%S3_SECRET_KEY%%/$S3_SECRET_KEY/g" /root/.s3cfg

# verify S3 config
s3cmd ls "s3://$S3_URL" > /dev/null

# set cron schedule TODO: check if the string is valid (five or six values separated by white space)
[[ -z "$CRON_SCHEDULE" ]] && CRON_SCHEDULE='0 2 * * *' && \
   echo "CRON_SCHEDULE set to default ('$CRON_SCHEDULE')"

USER=root
PASSWORD="$MYSQL_ROOT_PASSWORD"
[[ -z "$MYSQL_ROOT_PASSWORD" ]] && PASSWORD="$MYSQL_PASSWORD" && \
   echo "PASSWORD set to MYSQL_PASSWORD. USER is $MYSQL_USER" && USER="$MYSQL_USER"

# add a cron job
echo "$CRON_SCHEDULE root rm -rf /tmp/dump* && mysqldump -u $USER -p'$PASSWORD' --all-databases --single-transaction --force -h "$MYSQL_HOST" -P "$MYSQL_PORT" --result-file=/tmp/dump.sql --verbose >> /var/log/cron.log 2>&1 && gzip -c /tmp/dump.sql > /tmp/dump && s3cmd sync /tmp/dump s3://$S3_URL/ >> /var/log/cron.log 2>&1 && rm -rf /tmp/dump*" >> /etc/crontab
crontab /etc/crontab

exec "$@"

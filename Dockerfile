FROM mariadb:latest

# Create fake chown so docker scripts won't fail on Bluemix (ugly)
RUN mv /bin/chown /bin/chown.disabled && echo '#!/bin/bash' > /bin/chown && echo '/bin/chown.disabled "$@"' >> /bin/chown && echo 'exit 0' >> /bin/chown && chmod +x /bin/chown

# entrypoint
COPY entrypoint.sh /entrypoint.sh

# backups to Amazon S3
RUN apt-get update && apt-get install -y s3cmd && apt-get install -y cron && rm -rf /var/lib/apt/lists/*
COPY s3cfg /root/.s3cfg

ENTRYPOINT ["/entrypoint.sh"]

CMD ["cron","-f"]

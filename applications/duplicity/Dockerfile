# Always use harbor.test.slainte.at/dockerhub for public images, to avoid rate limits from dockerhub
FROM harbor.test.slainte.at/dockerhub/alpine:latest

LABEL maintainer="harbor@slainte.at"
LABEL Description="Test for Kyverno policies"

# Variable
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# timezone support
ENV TZ=Europe/Vienna
RUN apk add --no-cache tzdata &&\
    cp /usr/share/zoneinfo/${TZ} /etc/localtime  &&\
    echo $TZ > /etc/timezone &&\
    rm -rf /usr/share/zoneinfo  

RUN apk add --no-cache \
    bash \
    ca-certificates \
    duplicity \
    fuse3 \
    gnupg \
    openssh-client \
    rclone \
    sshfs \
    coreutils \
    util-linux

# Verzeichnisse für die Mounts
RUN mkdir -p /mnt/s3 /mnt/sshfs /run/secrets

# Sicherungsskript
COPY backup.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]

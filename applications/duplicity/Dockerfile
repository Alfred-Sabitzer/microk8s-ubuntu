FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       duplicity \
       fuse3 \
       openssh-client \
       python3 \
       s3fs \
       sshfs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY backup.py /app/backup.py

ENTRYPOINT ["python3", "/app/backup.py"]

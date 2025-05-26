# Alpine is chosen for its small footprint compared to Ubuntu
FROM golang:alpine AS golang
# Set destination for COPY
WORKDIR /app
# Copy the source code. Note the slash at the end, as explained in
# https://docs.docker.com/reference/dockerfile/#copy
COPY . ./
RUN chmod 755 *.sh
# timezone support
ENV TZ=Europe/Vienna
RUN apk add --update tzdata &&\
    cp /usr/share/zoneinfo/${TZ} /etc/localtime &&\
    echo ${TZ} > /etc/timezone && \
    rm -rf /usr/share/zoneinfo
# Variable Setting
ENV CGO_ENABLED=0
ENV GOOS=linux
# Build go executeable
RUN /bin/sh /app/go.sh

# Create small deployable Image  -- No Variable Substitution
FROM scratch  AS run-stage
#
LABEL maintainer="slainte@slainte.at"
LABEL Description="Hello World Example"
LABEL http="https://gitlab.com/Alfred-Sabitzer/microk8s-ubuntu/-/tree/master/Examples/helloworld?ref_type=heads"
#
COPY --from=golang /etc/localtime /etc/localtime
COPY --from=golang /etc/timezone /etc/timezone
COPY --from=golang /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs
COPY --from=golang /etc/passwd /etc/passwd
COPY --from=golang /etc/group /etc/group
COPY --from=golang /app/hello-world /.
COPY --from=golang /app/*.html /.
# Port we are listening
EXPOSE 8080
# Run - No Varaible Substituion (and in scratch, there is no shell)
ENTRYPOINT [ "/hello-world" ]
#
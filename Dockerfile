FROM alpine:3.18

# install everything we might need
RUN apk add --no-cache \
    bash \
    restic \
    jq \
    docker-cli \
    shadow \
    curl \
    tar \
    tzdata \
    busybox-suid \
    dcron

ENV PATH="/app/bin:$PATH"
WORKDIR /app

# copy scripts into /app
COPY ./bin/ /app/bin/

# by default, we run entrypoint which sets everything up and runs cron in the foreground
CMD ["/bin/bash", "/app/bin/start"]


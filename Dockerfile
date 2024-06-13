FROM alpine:3.19

RUN apk --no-cache add git git-lfs openssh-client bash && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

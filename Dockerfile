ARG SOURCE_DATE_EPOCH=0

FROM alpine:latest AS nginx
ARG SOURCE_DATE_EPOCH

RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates nginx curl openssl nginx-mod-http-lua && \
    rm -rf /var/lib/nginx/tmp /var/www/localhost && \
    mkdir -p /var/run/nginx/ /run/nginx/ /var/www/tmp /var/www/html && \
    ln -s /tmp /var/lib/nginx/tmp && \
		chmod 777 /var/www/tmp /var/www/html && \
		chown -R nginx /var/www && \
    truncate -s 0 /var/lib/nginx/html/index.html

RUN rm -rf /var/cache/*

COPY upload.sh /var/lib/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

FROM scratch
ARG SOURCE_DATE_EPOCH
COPY --from=nginx / /

EXPOSE 80
CMD ["/usr/sbin/nginx", "-e", "stderr"]

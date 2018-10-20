FROM debian:stretch
LABEL maintainer="André Santos <andre.forweb@gmail.com>"

ENV PHPFPM_HOSTNAME 127.0.0.1
ENV PHPFPM_PORT 9000

# "debconf: unable to initialize frontend: Dialog"
ENV DEBIAN_FRONTEND noninteractive

COPY docker-nginx-entrypoint.sh /usr/local/bin/docker-nginx-entrypoint

ADD https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 /usr/local/bin/confd

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        curl \
        openssl \
        ssl-cert \
        procps \
        gnupg1 \
        apt-transport-https \
        ca-certificates \
        gettext-base \
    && curl https://nginx.org/keys/nginx_signing.key -O \ 
        && apt-key add nginx_signing.key \
        && echo "deb http://nginx.org/packages/debian/ stretch nginx\
            \ndeb-src http://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list \
        && apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y \
            nginx \
    && chmod +x /usr/local/bin/docker-nginx-entrypoint \
    && chmod +x /usr/local/bin/confd \
    && mkdir -p /etc/confd/conf.d /etc/confd/templates \
    && unlink /etc/localtime \
    && ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/cert.pem \
    && ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/cert-key.pem \
    && mkdir -p /var/www/html/public \
    && cp /usr/share/nginx/html/index.html /var/www/html/public/index.html \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY confd-configs/conf.d/ /etc/confd/conf.d/
COPY confd-configs/templates/ /etc/confd/templates/
COPY nginx.conf /etc/nginx/

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80
EXPOSE 443

STOPSIGNAL SIGTERM

WORKDIR /var/www/html

ENTRYPOINT ["docker-nginx-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
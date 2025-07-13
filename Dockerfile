#
# Base CLI stage - for CLI operations
#
FROM serversideup/php:8.4-cli AS base-cli

ENV FIREFLY_III_PATH=/var/www/html COMPOSER_ALLOW_SUPERUSER=1 DEBIAN_FRONTEND=noninteractive PHP_MAX_EXECUTION_TIME=300 PHP_ERROR_REPORTING=24575 SHOW_WELCOME_MESSAGE=false BASE_IMAGE_BUILD=324 BASE_IMAGE_DATE="08-07-2025 06:27:28 UTC" PHP_OPCACHE_ENABLE=1

COPY .docker/conf/locale.gen                     /etc/locale.gen
COPY .docker/scripts/wait-for-it.sh              /usr/local/bin/wait-for-it.sh
COPY .docker/scripts/finalize-image.sh           /usr/local/bin/finalize-image.sh
COPY .docker/scripts/execute-things-cli.sh       /etc/entrypoint.d/11-execute-things.sh

USER root
RUN set -eux; \
    chmod uga+x /usr/local/bin/wait-for-it.sh && \
    chmod uga+x /usr/local/bin/finalize-image.sh && \
    apt update && apt install -y curl locales && \
    install-php-extensions intl bcmath memcached sockets && \
    rm -rf /var/lib/apt/lists/*

USER www-data

#
# Base web stage - for web application
#
FROM serversideup/php:8.4-fpm-nginx AS base-web

ENV FIREFLY_III_PATH=/var/www/html COMPOSER_ALLOW_SUPERUSER=1 DEBIAN_FRONTEND=noninteractive PHP_MAX_EXECUTION_TIME=300 PHP_ERROR_REPORTING=24575 SHOW_WELCOME_MESSAGE=false BASE_IMAGE_BUILD=324 BASE_IMAGE_DATE="08-07-2025 06:27:28 UTC" PHP_OPCACHE_ENABLE=1

VOLUME $FIREFLY_III_PATH/storage/upload

COPY .docker/conf/locale.gen                     /etc/locale.gen
COPY .docker/scripts/wait-for-it.sh              /usr/local/bin/wait-for-it.sh
COPY .docker/scripts/finalize-image.sh           /usr/local/bin/finalize-image.sh
COPY .docker/scripts/execute-things-web.sh       /etc/entrypoint.d/11-execute-things.sh

USER root
RUN set -eux; \
    chmod uga+x /usr/local/bin/wait-for-it.sh && \
    chmod uga+x /usr/local/bin/finalize-image.sh && \
    apt update && apt install -y curl locales && \
    install-php-extensions intl bcmath memcached sockets && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

USER www-data

#
# CLI stage - ready to use CLI version
#
FROM base-cli AS cli-dev

# CLI stage is ready to use as-is from base-cli

#
# Web application stage - final web application
#
FROM base-web AS web-dev

# Health check
HEALTHCHECK --start-period=5m --interval=5s --timeout=3s --retries=3 \
    CMD [ "sh", "-c", "curl --insecure --silent --location --show-error --fail http://localhost:8080$HEALTHCHECK_PATH || exit 1" ]

# Copy application files
COPY .docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY .docker/counter.txt /var/www/counter-main.txt
COPY .docker/date.txt /var/www/build-date-main.txt

USER root
RUN chmod uga+x /usr/local/bin/entrypoint.sh
USER www-data

COPY . /var/www/html

# Copy alerts
COPY .docker/alerts.json /var/www/html/resources/alerts.json
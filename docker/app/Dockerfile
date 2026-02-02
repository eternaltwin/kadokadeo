###
#
# docker build --pull --tag kadokadeo:dev --file docker/app/Dockerfile ./
#
###

FROM docker.io/library/node:20.19.3-alpine3.22 AS frontend

WORKDIR "/kadokadeo"

COPY ["./package.json", "./"]
COPY ["./yarn.lock", "./"]
COPY ["./.yarn", "./.yarn"]
RUN yarn

COPY ["./vite.config.js", "./"]
COPY ["./resources", "./resources"]
COPY ["./public", "./public"]
RUN yarn build

FROM docker.io/library/php:8.3-fpm AS backend

ARG UID
ARG GID

RUN apt-get update && apt-get install -y \
    git \
    gnupg \
    zip \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    supervisor \
    cron \
    haxe \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl zip pdo pdo_pgsql pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /www

RUN groupadd -g $GID dev \
    && useradd -m -u $UID -g dev dev \
    && chown -R dev:dev /www

USER dev

COPY --chown=dev:dev ["composer.json", "/www/composer.json"]
COPY --chown=dev:dev ["composer.lock", "/www/composer.lock"]
COPY --chown=dev:dev ["artisan", "/www/artisan"]
COPY --chown=dev:dev ["app", "/www/app"]
COPY --chown=dev:dev ["bootstrap", "/www/bootstrap"]
COPY --chown=dev:dev ["config", "/www/config"]
COPY --chown=dev:dev ["database", "/www/database"]
COPY --chown=dev:dev ["public", "/www/public"]
COPY --chown=dev:dev ["resources", "/www/resources"]
COPY --chown=dev:dev ["routes", "/www/routes"]
COPY --chown=dev:dev ["storage", "/www/storage"]

RUN composer install --no-dev --no-progress --no-interaction
RUN mkdir /home/dev/haxelib \
    && haxelib setup /home/dev/haxelib \
    && haxelib install --always resources/hx/install.hxml

COPY --from=frontend --chown=dev:dev ["/kadokadeo/public/build", "/www/public/build"]
USER root

COPY ["docker/app/conf/php.ini", "$PHP_INI_DIR/app.ini"]
COPY ["docker/app/conf/crontab", "/etc/cron.d/kadokadeo"]
COPY ["docker/app/conf/supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"]

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

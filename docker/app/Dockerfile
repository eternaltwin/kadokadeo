# Dockerfile
FROM php:8.1-apache

#For mac and windows
ARG HOST_IP=host.docker.internal
ARG UID=1000
ARG GID=1000
#For linux
#ARG HOST_IP=172.17.0.1

EXPOSE 80
WORKDIR /www

# Install Composer
RUN apt-get update -qq && \
    apt-get install -qy \
    git \
    gnupg \
    unzip \
    zip && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Postgre PDO && PHP intl
RUN apt-get -y update \
    && apt-get install -y libpq-dev libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY conf/php.ini /usr/local/etc/php/conf.d/app.ini

# Apache
COPY conf/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY conf/apache.conf /etc/apache2/conf-available/z-app.conf

RUN groupadd dev -g $GID
RUN useradd dev -u $UID -g dev -d /home/dev -m

RUN a2enmod rewrite remoteip && \
    a2enconf z-app
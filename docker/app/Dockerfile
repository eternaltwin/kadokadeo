# Dockerfile
FROM php:8.3-apache

#For mac and windows
ARG HOST_IP=host.docker.internal
ARG UID=1000
ARG GID=1000
#For linux
#ARG HOST_IP=172.17.0.1

EXPOSE 80

# Install Composer
RUN apt-get update -qq && \
    apt-get install -qy \
    git \
    gnupg \
    unzip \
    zip \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    build-essential \
    scons \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxinerama-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxi-dev \
    libxrandr-dev \
    libwayland-dev \
    emscripten \
    libfontconfig1 \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY conf/php.ini /usr/local/etc/php/conf.d/app.ini

# Apache
COPY conf/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY conf/apache.conf /etc/apache2/conf-available/z-app.conf

RUN groupadd dev -g $GID && useradd dev -u $UID -g dev -d /home/dev -m

RUN a2enmod rewrite remoteip && \
    a2enconf z-app

WORKDIR /app

RUN git clone -b 4.4-stable --single-branch https://github.com/godotengine/godot.git

WORKDIR /app/godot

# Build Godot for headless/server
RUN scons platform=linuxbsd target=editor

# Build Godot for web
RUN scons \
    platform=web \
    target=template_release \
    disable_3d=yes \
    module_text_server_adv_enabled=no \
    module_text_server_fb_enabled=yes \
    lto=full \
    threads=no \
    disable_advanced_gui=yes \
    module_basis_universal_enabled=no \
    module_bmp_enabled=no \
    module_camera_enabled=no \
    module_csg_enabled=no \
    module_dds_enabled=no \
    module_enet_enabled=no \
    module_gridmap_enabled=no \
    module_hdr_enabled=no \
    module_jsonrpc_enabled=no \
    module_ktx_enabled=no \
    module_mbedtls_enabled=yes \
    module_meshoptimizer_enabled=no \
    module_minimp3_enabled=no \
    module_mobile_vr_enabled=no \
    module_msdfgen_enabled=no \
    module_multiplayer_enabled=no \
    module_noise_enabled=no \
    module_navigation_enabled=no \
    module_ogg_enabled=no \
    module_openxr_enabled=no \
    module_raycast_enabled=yes \
    module_regex_enabled=no \
    module_squish_enabled=no \
    module_svg_enabled=yes \
    module_tga_enabled=no \
    module_theora_enabled=no \
    module_tinyexr_enabled=no \
    module_upnp_enabled=no \
    module_vhacd_enabled=no \
    module_vorbis_enabled=no \
    module_webrtc_enabled=no \
    module_websocket_enabled=no \
    module_webxr_enabled=no \
    module_zip_enabled=no \
    production=yes

WORKDIR /www

USER dev

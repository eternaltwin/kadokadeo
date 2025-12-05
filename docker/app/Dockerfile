###
#
# docker build --pull --tag kadokadeo:dev --file docker/app/Dockerfile ./
#
###

FROM docker.io/library/debian:trixie-slim AS godot

ARG ARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    unzip \
    curl \
    pkg-config \
    python3 \
    scons \
    emscripten \
    libfontconfig1 \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp /var/cache/apt/archives/*.deb


WORKDIR /app

RUN git clone -b 4.4-stable --single-branch https://github.com/godotengine/godot.git \
    && curl -L -o godot.zip "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.${ARCH}.zip" \
    && unzip godot.zip -d godot_editor \
    && rm godot.zip \
    && mv godot_editor/Godot_v4.4.1-stable_linux.${ARCH} godot_editor/godot \
    && chmod +x godot_editor/godot

WORKDIR /app/godot

# Build Godot for web
RUN scons \
    platform=web \
    target=template_release \
    disable_3d=yes \
    module_text_server_adv_enabled=no \
    module_text_server_fb_enabled=yes \
    lto=full \
    threads=yes\
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

RUN mv /app/godot/bin/godot.web.template_release.wasm32.zip /app \
    && rm -rf /app/godot \
    && mkdir /app/gamesdata \
    && unzip /app/godot.web.template_release.wasm32.zip -d /app/gamesdata

WORKDIR /app
RUN git clone --single-branch https://gitlab.com/eternaltwin/kadokadeo/kadokadeo.git
WORKDIR /app/kadokadeo/resources/games/godot

RUN git submodule update --init --recursive \
    && git submodule update --recursive --remote

RUN find * -type d -prune | while read -r d; do \
    if [ "$d" = "output" ]; then continue; fi; \
    echo "Processing game $d"; \
    python3 set_template.py /app/godot.web.template_release.wasm32.zip --file "$d/export_presets.cfg" --debug /app/godot.web.template_release.wasm32.zip; \
    /app/godot_editor/godot --headless --path $d --export-release "Web" /app/kadokadeo/resources/games/godot/output/$d; \
    mv output/$d.pck /app/gamesdata/$d.pck; \
    rm output/*; \
    done

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
COPY --chown=dev:dev ["routes", "/www/routes"]
COPY --chown=dev:dev ["storage", "/www/storage"]
RUN composer install --no-dev --no-progress --no-interaction

COPY --from=frontend --chown=dev:dev ["/kadokadeo/public/build", "/www/public/build"]
COPY --from=godot --chown=dev:dev ["/app/gamesdata/*", "/www/public/gamesdata/"]
COPY --from=godot --chown=dev:dev ["/app/godot.web.template_release.wasm32.zip", "/godot/godot.web.template_release.wasm32.zip"]
COPY --from=godot --chown=dev:dev ["/app/godot_editor/godot", "/godot/godot"]
USER root

COPY ["docker/app/conf/php.ini", "$PHP_INI_DIR/app.ini"]
COPY ["docker/app/conf/crontab", "/etc/cron.d/kadokadeo"]
COPY ["docker/app/conf/supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"]

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

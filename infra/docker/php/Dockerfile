FROM php:8.4-fpm-alpine

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        autoconf \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libzip-dev \
        oniguruma-dev \
        icu-dev \
    && apk add --no-cache \
       fcgi \
       libpng \
       libjpeg-turbo \
       freetype \
       libzip \
       icu-libs \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        intl \
        bcmath \
        pdo_mysql \
        pcntl \
        zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps \
    && rm -rf /tmp/pear

# PHP production ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG UID=1000
ARG GID=1000

USER root

RUN addgroup -g $GID api \
    && adduser -D -u $UID -G api api \
    && mkdir -p /home/api/.composer \
    && chown -R api:api /home/api

USER api

WORKDIR /var/www/api

EXPOSE 9000
CMD ["php-fpm"]

FROM php:8.1.7-fpm-alpine3.16

# Add bash
RUN apk add --no-cache bash

# Install packages and remove default server definition
RUN apk --no-cache add gnupg 
RUN apk --no-cache add autoconf 
RUN apk --no-cache add make 
RUN apk --no-cache add g++ 
RUN apk --no-cache add nginx 
RUN apk --no-cache add supervisor 
RUN apk --no-cache add zlib-dev 
RUN apk --no-cache add libpng-dev 
RUN apk --no-cache add icu-dev 
RUN apk --no-cache add icu-libs 
RUN apk --no-cache add librdkafka-dev 
RUN apk --no-cache add git 
RUN apk --no-cache add libzip-dev 
RUN apk --no-cache add shadow 
RUN apk --no-cache add nodejs
RUN apk --no-cache add file 
RUN apk --no-cache add imagemagick 
RUN apk --no-cache add imagemagick-dev
# RUN rm /etc/nginx/conf.d/default.conf

# Install PHP extensions
RUN docker-php-ext-install bcmath gd exif pcntl intl zip pdo pdo_mysql

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install unixodbc-dev required for pecl
RUN apk add --allow-untrusted unixodbc-dev

# Install SQL Server Drivers
RUN pecl channel-update pecl.php.net
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN pecl install rdkafka    
RUN pecl install imagick

RUN docker-php-ext-enable --ini-name 30-sqlsrv.ini sqlsrv
RUN docker-php-ext-enable --ini-name 35-pdo_sqlsrv.ini pdo_sqlsrv
RUN docker-php-ext-enable rdkafka
RUN docker-php-ext-enable imagick

# Install Xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable --ini-name 30-xdebug.ini xdebug

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Add application
WORKDIR /var/www/html

# Add a volume so that the external source code can be hooked
VOLUME [ "/var/www/html" ]

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

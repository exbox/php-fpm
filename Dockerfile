#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'php-fpm' base Image, visit its repository on Github
#    https://github.com/Laradock/php-fpm
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/laradock/php-fpm/tags/
#
# Note: Base Image name format {image-tag}-{php-version}
#

FROM laradock/php-fpm:2.0-72

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

RUN apt-get update -yqq && apt-get -y install procps

ARG INSTALL_SOAP=false
RUN if [ ${INSTALL_SOAP} = true ]; then \
    # Install the soap extension
    apt-get update -yqq && \
    apt-get -y install libxml2-dev php-soap && \
    docker-php-ext-install soap \
;fi

ARG INSTALL_PGSQL=true
RUN if [ ${INSTALL_PGSQL} = true ]; then \
    # Install the pgsql extension
    apt-get update -yqq && \
    docker-php-ext-install pgsql \
;fi

ARG INSTALL_PG_CLIENT=true
RUN if [ ${INSTALL_PG_CLIENT} = true ]; then \
    # Create folders if not exists (https://github.com/tianon/docker-brew-debian/issues/65)
    mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7 && \
    # Install the pgsql client
    apt-get update -yqq && \
    apt-get install -y postgresql-client \
;fi

ARG INSTALL_XDEBUG=false
RUN if [ ${INSTALL_XDEBUG} = true ]; then \
    # Install the xdebug extension
    pecl install xdebug && \
    docker-php-ext-enable xdebug \
;fi

ARG INSTALL_BLACKFIRE=false
RUN if [ ${INSTALL_XDEBUG} = false -a ${INSTALL_BLACKFIRE} = true ]; then \
    version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
;fi

ARG INSTALL_PHPREDIS=true
RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis Extension
    printf "\n" | pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis \
;fi

ARG INSTALL_SWOOLE=false
RUN if [ ${INSTALL_SWOOLE} = true ]; then \
    # Install Php Swoole Extension
    pecl install swoole \
    &&  docker-php-ext-enable swoole \
;fi

ARG INSTALL_MONGO=false
RUN if [ ${INSTALL_MONGO} = true ]; then \
    # Install the mongodb extension
    pecl install mongodb && \
    docker-php-ext-enable mongodb \
;fi

ARG INSTALL_AMQP=false
RUN if [ ${INSTALL_AMQP} = true ]; then \
    apt-get update && \
    apt-get install librabbitmq-dev -y && \
    # Install the amqp extension
    pecl install amqp && \
    docker-php-ext-enable amqp \
;fi

ARG INSTALL_ZIP_ARCHIVE=true
RUN if [ ${INSTALL_ZIP_ARCHIVE} = true ]; then \
    # Install the zip extension
    docker-php-ext-install zip \
;fi

ARG INSTALL_BCMATH=true
RUN if [ ${INSTALL_BCMATH} = true ]; then \
    # Install the bcmath extension
    docker-php-ext-install bcmath \
;fi

ARG INSTALL_GMP=false
RUN if [ ${INSTALL_GMP} = true ]; then \
    # Install the GMP extension
	apt-get update -yqq && \
	apt-get install -y libgmp-dev && \
    docker-php-ext-install gmp \
;fi

ARG INSTALL_MEMCACHED=true
RUN if [ ${INSTALL_MEMCACHED} = true ]; then \
    # Install the php memcached extension
    curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p memcached \
    && tar -C memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && ( \
        cd memcached \
        && phpize \
        && ./configure \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r memcached \
    && rm /tmp/memcached.tar.gz \
    && docker-php-ext-enable memcached \
;fi

ARG INSTALL_EXIF=true
RUN if [ ${INSTALL_EXIF} = true ]; then \
    # Enable Exif PHP extentions requirements
    docker-php-ext-install exif \
;fi

USER root

ARG INSTALL_AEROSPIKE=false
ENV INSTALL_AEROSPIKE ${INSTALL_AEROSPIKE}

RUN if [ ${INSTALL_AEROSPIKE} = true ]; then \
    # Fix dependencies for PHPUnit within aerospike extension
    apt-get update -yqq && \
    apt-get -y install sudo wget && \
    # Install the php aerospike extension (using 7.2.0-in-progress branch until support for 7.2 on master)
    curl -L -o /tmp/aerospike-client-php.tar.gz "https://github.com/aerospike/aerospike-client-php/archive/7.2.0-in-progress.tar.gz" \
    && mkdir -p aerospike-client-php \
    && tar -C aerospike-client-php -zxvf /tmp/aerospike-client-php.tar.gz --strip 1 \
    && ( \
        cd aerospike-client-php/src \
        && phpize \
        && ./build.sh \
        && make install \
    ) \
    && rm /tmp/aerospike-client-php.tar.gz \
    && docker-php-ext-enable aerospike \
;fi

ARG INSTALL_OPCACHE=true
RUN if [ ${INSTALL_OPCACHE} = true ]; then \
    docker-php-ext-install opcache \
;fi

# Copy opcache configration
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

ARG INSTALL_MYSQLI=true
RUN if [ ${INSTALL_MYSQLI} = true ]; then \
    docker-php-ext-install mysqli \
;fi

ARG INSTALL_TOKENIZER=true
RUN if [ ${INSTALL_TOKENIZER} = true ]; then \
    docker-php-ext-install tokenizer \
;fi

ARG INSTALL_INTL=true
RUN if [ ${INSTALL_INTL} = true ]; then \
    # Install intl and requirements
    apt-get update -yqq && \
    apt-get install -y zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl \
;fi

ARG INSTALL_GHOSTSCRIPT=false
RUN if [ ${INSTALL_GHOSTSCRIPT} = true ]; then \
    # Install the ghostscript extension
    # for PDF editing
    apt-get update -yqq \
    && apt-get install -y \
    poppler-utils \
    ghostscript \
;fi

ARG INSTALL_LDAP=false
RUN if [ ${INSTALL_LDAP} = true ]; then \
    apt-get update -yqq && \
    apt-get install -y libldap2-dev && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap \
;fi

USER root
ARG INSTALL_IMAGE_OPTIMIZERS=true
ENV INSTALL_IMAGE_OPTIMIZERS ${INSTALL_IMAGE_OPTIMIZERS}
RUN if [ ${INSTALL_IMAGE_OPTIMIZERS} = true ]; then \
    apt-get update -yqq && \
    apt-get install -y --force-yes jpegoptim optipng pngquant gifsicle \
;fi

USER root
ARG INSTALL_IMAGEMAGICK=true
ENV INSTALL_IMAGEMAGICK ${INSTALL_IMAGEMAGICK}
RUN if [ ${INSTALL_IMAGEMAGICK} = true ]; then \
    apt-get update -y && \
    apt-get install -y libmagickwand-dev imagemagick && \
    pecl install imagick && \
    docker-php-ext-enable imagick \
;fi

COPY ./imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

ARG INSTALL_IMAP=false
ENV INSTALL_IMAP ${INSTALL_IMAP}
RUN if [ ${INSTALL_IMAP} = true ]; then \
    apt-get update && \
    apt-get install -y libc-client-dev libkrb5-dev && \
    rm -r /var/lib/apt/lists/* && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap \
;fi

RUN php -v | head -n 1 | grep -q "PHP 7.2."

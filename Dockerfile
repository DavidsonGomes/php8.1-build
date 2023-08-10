FROM php:8.1-apache

USER root

WORKDIR /var/www/html

RUN apt-get update
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs

ENV COMPOSER_MEMORY_LIMIT -1

RUN apt-get update \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -y curl \
  sudo \
  software-properties-common \
  build-essential \
  apache2 \
  cron \
  bzip2 \
  graphviz \
  dnsutils \
  wget \
  memcached \
  libmemcached-dev \
  libmemcached-tools \
  gnupg \
  libpcre3-dev \
  nano \
  htop \
  zip \
  unzip \
  git \
  supervisor \
  g++ \
  zlib1g-dev \
  libjpeg-dev \
  libmagickwand-dev \
  inetutils-ping \
  libz-dev \
  libpq-dev \
  libcurl4-openssl-dev \
  libaprutil1-dev \
  libssl-dev \
  libicu-dev \
  libxml2-dev \
  sysvbanner \
  libzip-dev \
  libjpeg62-turbo-dev \
  imagemagick \
  ca-certificates \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgbm1 \
  libgcc1 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libstdc++6 \
  libx11-6 \
  libxss1 \
  libxtst6 \
  lsb-release \
  wget \
  xdg-utils \
  libc-client-dev \
  libjpeg-dev \
  gifsicle && apt-get clean && rm -rf /var/lib/apt/lists/* &&  rm -rf /tmp/library-scripts \
  apt-get purge

RUN PHP_OPENSSL=yes pecl install ev \
    && docker-php-ext-enable ev

# Installing Apache mod-pagespeed
#RUN curl -o /home/mod-pagespeed-beta_current_amd64.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
#RUN dpkg -i /home/mod-pagespeed-*.deb
#RUN apt-get -f install

RUN	docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install -j "$(nproc)" \
  bcmath \
  exif \
  gd \
  pdo \
  intl \
  xml \
  pdo_mysql \
  soap \
  pcntl \
  mysqli \
  opcache \
  zip \
  calendar

RUN printf "\n" | printf "\n" | pecl install redis \
  ; \
  pecl install imagick \
  apcu \
  mailparse \
  memcached \
  mongodb \
  openswoole

RUN docker-php-ext-enable imagick \
  bcmath \
  redis \
  opcache \
  mailparse \
  memcached \
  apcu \
  mongodb

# Enable apache modules
RUN a2enmod setenvif \
  headers \
  deflate \
  filter \
  expires \
  rewrite \
  include \
  ext_filter

COPY php/opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

COPY php/openswoole.ini /usr/local/etc/php/conf.d/openswoole.ini

COPY php/php81-recommended.ini /usr/local/etc/php/conf.d/php81-recommended.ini

COPY apache/optimize.conf /etc/apache2/conf-available/optimize.conf

RUN a2enconf optimize

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN chown -R www-data:www-data /var/www/html \
    && a2enmod rewrite

RUN service apache2 start

RUN apt-get install supervisor -y

COPY supervisor/horizon.conf /etc/supervisor/conf.d/horizon.conf

RUN service supervisor enable

RUN service supervisor start

RUN service apache2 restart

EXPOSE 80
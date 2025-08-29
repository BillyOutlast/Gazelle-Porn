FROM ubuntu:24.04

WORKDIR /var/www

# Software package layer
# Nodesource setup comes after yarnpkg because it runs `apt-get update`

RUN apt-get update
RUN apt install -y software-properties-common
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
RUN apt-get update


RUN apt install -y php8.4


RUN  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cron \
    curl \
    git \
    gnupg \
    imagemagick \
    libboost-dev \
    libbz2-dev \
    libssl-dev \
    libsqlite3-dev \
    libtcmalloc-minimal4 \
    make \
    mariadb-client \
    netcat-openbsd \
    nginx \
    php8.4-cli \
    php8.4-curl \
    php8.4-fpm \
    php8.4-gd \
    php8.4-mbstring \
    php8.4-mysql \
    php8.4-xml \
    php8.4-zip \
    php8.4-yaml \
    php8.4-apcu \
    php8.4-bcmath \
    php8.4-memcached \
    php8.4-xdebug \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-dev \
    unzip \
    wget \
    zlib1g-dev \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends \
    nodejs \
    yarn

# Python tools layer
RUN apt-get update && apt-get install -y python3-chardet

RUN curl -s https://getcomposer.org/installer | php
RUN mv composer.phar /usr/bin/composer

# Puppeteer layer
# This installs the necessary packages to run the bundled version of chromium for puppeteer
RUN apt-get install -y --no-install-recommends \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgcc1 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    fonts-liberation \
    libnss3 \
    lsb-release \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# If running Docker >= 1.13.0 use docker run's --init arg to reap zombie processes, otherwise
# uncomment the following lines to have `dumb-init` as PID 1
# ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
# RUN chmod +x /usr/local/bin/dumb-init
# ENTRYPOINT ["dumb-init", "--"]

# Uncomment to skip the chromium download when installing puppeteer. If you do,
# you'll need to launch puppeteer with:
#     browser.launch({executablePath: 'google-chrome-unstable'})
# ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

COPY . /var/www
# Permissions and configuration layer
RUN useradd -ms /bin/bash gazelle \
    && chown -R gazelle:gazelle /var/www \
    && cp /var/www/.docker/web/php.ini /etc/php/8.4/cli/php.ini \
    && cp /var/www/.docker/web/php.ini /etc/php/8.4/fpm/php.ini \
    && cp /var/www/.docker/web/xdebug.ini /etc/php/8.4/mods-available/xdebug.ini \
    && rm -f /etc/nginx/sites-enabled/default \
    && sed -i 's|unix:/var/run/php/php-fpm.sock|unix:/var/run/php/php8.4-fpm.sock|g' /etc/nginx/sites-available/default || true \
    && sed -i 's|unix:/var/run/php/php-fpm.sock|unix:/var/run/php/php8.4-fpm.sock|g' /etc/nginx/nginx.conf || true

EXPOSE 80/tcp
EXPOSE 9002/tcp
EXPOSE 35729/tcp



ENTRYPOINT [ "/bin/bash", "/var/www/.docker/web/entrypoint.sh" ]

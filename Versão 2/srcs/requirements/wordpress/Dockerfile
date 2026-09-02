FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    default-mysql-client \
    mariadb-client \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# ===================== WP-CLI =====================

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# ===================== WORDPRESS DIRECTORY =====================

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
RUN mkdir -p /run/php

# ===================== PHP-FPM CONFIGURATION =====================

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf


# ===================== STARTUP SCRIPT =====================

COPY tools/init_wp.sh /usr/local/bin/init_wp.sh

RUN chmod +x /usr/local/bin/init_wp.sh

WORKDIR /var/www/html

EXPOSE ${WORDPRESS_INTERNAL_PORT}

ENTRYPOINT ["/usr/local/bin/init_wp.sh"]

FROM php:7.2-apache-stretch
MAINTAINER Christian Winkler <christian.winkler@cwkr.de>

ENV DOKUWIKI_VERSION=2018-04-22b
ARG DOKUWIKI_MD5SUM=605944ec47cd5f822456c54c124df255

RUN apt-get update && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libbz2-dev wget && \
    apt-get clean autoclean && apt-get autoremove

RUN wget -q -O /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_MD5SUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir /opt/dokuwiki && \
    tar -zxf /dokuwiki.tgz -C /opt/dokuwiki --strip-components 1
RUN chown -vR www-data:www-data /opt/dokuwiki
RUN rm -v /dokuwiki.tgz

RUN mv -v "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN sed -i "s/expose_php = On/expose_php = Off/g" "$PHP_INI_DIR/php.ini"
RUN sed -i "s/memory_limit = 128M/memory_limit = 256M/g" "$PHP_INI_DIR/php.ini"
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 10M/g" "$PHP_INI_DIR/php.ini"
RUN sed -i "s/disable_functions =/disable_functions = exec,passthru,shell_exec,system,proc_open,proc_close,proc_get_status,proc_nice,proc_terminate,popen,curl_exec,curl_multi_exec/g" "$PHP_INI_DIR/php.ini"
RUN sed -i "s/session.cookie_httponly =/session.cookie_httponly = 1/g" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install bz2
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && docker-php-ext-install gd
RUN docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd && docker-php-ext-install pdo_mysql
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd && docker-php-ext-install mysqli

COPY dokuwiki.conf /etc/apache2/sites-available/
RUN a2dissite 000-default && a2ensite dokuwiki && a2enmod rewrite

VOLUME ["/opt/dokuwiki/data/","/opt/dokuwiki/lib/plugins/","/opt/dokuwiki/conf/","/opt/dokuwiki/lib/tpl/"]

FROM debian:wheezy
MAINTAINER Hauro <>

# The directory /var/www/html is used for all web data. This will be the default
# in Debian 8.x (Jessie). /var/www/html/owncloud is used as web root.

# TODO: do all logging in /var/log/owncloud/?

# Divert initctl so we can "start" service during package installation
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Install OwnCloud dependencies. The list is composed in "blocks" that match
# the ordering in the OwnCloud manual for easier comparison. Some named mods
# are part of the PHP4 CLI SAPI.
#
# Included in php5-cli:
#  - Core ctype dom iconv libxml mbstring posix SimpleXML xmlwriter zip zlib
#  - fileinfo bz2 openssl
#  - exif
#  - ftp
#
# TODO: Replace xcache with apcu? (Not in Wheezy. Could be done in Jessie.)
#
RUN \
  apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
   apt-get install -y \
    cron curl bzip2 supervisor \
    patch \
    nginx-light \
    php5-cli php5-gd php5-json \
    php5-pgsql php5-sqlite php5-mysqlnd \
    php5-curl php5-intl php5-mcrypt \
    \
    php5-gmp \
    php5-xcache \
    php5-imagick \
    php5-fpm \
    smbclient \
  && rm -rf /var/lib/apt/lists/*

RUN \
  mkdir -p /var/www/html /var/log/owncloud \
  && curl -L -o /tmp/owncloud.tar.bz2 https://download.owncloud.org/community/owncloud-8.0.2.tar.bz2 \
  && echo "46c73b6ae3841e856d139537d21e1c7029c64d79fd7c45c794e27cb1469d7f01  /tmp/owncloud.tar.bz2" | sha256sum -c \
  && tar -C /var/www/html -xjvf /tmp/owncloud.tar.bz2 \
## old auto patch config
##  && ( \
##    cd /var/www/html/owncloud \
##    && curl https://github.com/chris-se/owncloud-core/commit/1377ebc7e9b9a5bed36b5a1ca8da2c6ef35eb74a.patch | patch -p1 \
##    && curl https://github.com/chris-se/owncloud-core/commit/535757bc427d91a6b96b7b3a145d83e1fefef43a.patch | patch -p1 \
##    ) \
##
  && mkdir -p /var/www/html/owncloud/data /var/tmp/owncloud \
  && find /var/www/html/owncloud/ -type f -print0 | xargs -0 chmod 0640 \
  && find /var/www/html/owncloud/ -type d -print0 | xargs -0 chmod 0750 \
  && chown -R root:www-data /var/www/html/owncloud /var/tmp/owncloud \
  && for d in apps config data ; do chown -R www-data:www-data /var/www/html/owncloud/$d ; done \
  && for f in .htaccess ; do chown root:www-data /var/www/html/owncloud/$f ; chmod 0644 /var/www/html/owncloud/$f ; done \
  && rm -f /tmp/owncloud.tar.bz2

# Install additional files into container root
ADD files/ /

RUN \
  ln -s ../mods-available/owncloud.ini /etc/php5/conf.d/90-owncloud.ini \
  && rm -f /etc/nginx/sites-enabled/default \
  && ln -s ../sites-available/owncloud /etc/nginx/sites-enabled/owncloud \
  && chmod +x /usr/bin/owncloud-bootstrap

## adds newest version of calendar app
 RUN \
  curl -L -o /tmp/calendar.tar.gz https://github.com/owncloud/calendar/archive/v8.0.3RC3.tar.gz \
  && tar -C /var/www/html/owncloud/apps -xvf /tmp/calendar.tar.gz \
  && mv /var/www/html/owncloud/apps/calendar-8.0.3RC3 /var/www/html/owncloud/apps/calendar \
  && chown -R www-data:www-data /var/www/html/owncloud/apps/calendar

EXPOSE 80

# Call the bootstrop script. It fixes some permission problems if you
# use volumes in data containers. (And you really should, FWIW.)
# ENTRYPOINT  ["owncloud-bootstrap"]


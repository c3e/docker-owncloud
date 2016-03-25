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
RUN echo "helloworld"

RUN  apt-get update && DEBIAN_FRONTEND=noninteractive
RUN  apt-get install -y \
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
    \
    htop net-tools less vim

RUN rm -rf /var/lib/apt/lists/*

RUN \
  mkdir -p /var/www/html /var/log/owncloud \
  
  && curl -L -o /tmp/owncloud.tar.bz2 https://download.owncloud.org/community/owncloud-8.1.0.tar.bz2 \
  && echo "3d308d3b3d7083ca9fbfdde461ccd4bb66b7fb36f922ade5e6baf1b03bf174ee  /tmp/owncloud.tar.bz2" | sha256sum -c \
  
  #&& curl -L -o /tmp/owncloud.tar.bz2 https://download.owncloud.org/community/owncloud-9.0.0.tar.bz2 \
  #&& echo "d16737510a77a81489f7c4d5e19b0756fa2ea1c5081ba174b0fec0f00da3a77c  /tmp/owncloud.tar.bz2" | sha256sum -c \
  
  && tar -C /var/www/html -xjvf /tmp/owncloud.tar.bz2 \
  && mkdir -p /var/www/html/owncloud/data /var/tmp/owncloud \
  && find /var/www/html/owncloud/ -type f -print0 | xargs -0 chmod 0640 \
  && find /var/www/html/owncloud/ -type d -print0 | xargs -0 chmod 0750 \
  && chown -R root:www-data /var/www/html/owncloud /var/tmp/owncloud \
  && for d in apps config data ; do chown -R www-data:www-data /var/www/html/owncloud/$d ; done \
  && for f in .htaccess ; do chown root:www-data /var/www/html/owncloud/$f ; chmod 0644 /var/www/html/owncloud/$f ; done \
  && rm -f /tmp/owncloud.tar.bz2

# Install additional files into container root
ADD files/etc /etc/

ADD files/usr /usr/

RUN ln -s ../mods-available/owncloud.ini /etc/php5/conf.d/90-owncloud.ini
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -s ../sites-available/owncloud /etc/nginx/sites-enabled/owncloud
RUN chmod +x /usr/bin/owncloud-bootstrap

# install calendar: https://github.com/owncloud/calendar/releases/download/v0.7.2/calendar.zip

#RUN apt-get update && apt-get install -y tar

#RUN curl -L -o /tmp/calendar.zip https://github.com/owncloud/calendar/releases/download/v0.7.2/calendar.zip 
#RUN curl -L -o /tmp/calendar.tar.gz https://github.com/owncloud/calendar/releases/download/v1.0/calendar.tar.gz
#RUN tar -zxvf /tmp/calendar.tar.gz -C /var/www/html/owncloud/apps 
#RUN chown -R www-data:www-data /var/www/html/owncloud/apps/calendar

EXPOSE 443

# Call the bootstrop script. It fixes some permission problems if you
# use volumes in data containers. (And you really should, FWIW.)
ENTRYPOINT  ["/usr/bin/owncloud-bootstrap"]


CMD ["/bin/bash"]



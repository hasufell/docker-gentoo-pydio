FROM        mosaiksoftware/gentoo-nginx:latest
MAINTAINER  Julian Ospald <hasufell@gentoo.org>


##### PACKAGE INSTALLATION #####

# install nginx
RUN chgrp paludisbuild /dev/tty && cave resolve -c docker-pydio -x && \
	cave resolve -z -1 mail-mta/ssmtp -F mail-mta/ssmtp -U '*/*' -x && \
	rm -rf /usr/portage/distfiles/* /srv/binhost/*

# update etc files... hope this doesn't screw up
RUN etc-update --automode -5

################################

## configure mailer
COPY config/mailer.conf /etc/ssmtp/ssmtp.conf

## pydio data

# fetch pydio release
RUN wget http://dl.ajaxplorer.info/repos/el6/pydio-stable/pydio-6.0.8-1.noarch.rpm

# install pydio
RUN rpm2cpio pydio-6.0.8-1.noarch.rpm | cpio -idmv && \
	rm -rf /etc/httpd /var/log/pydio && \
	find /usr/share/pydio -name '.htaccess' -delete && \
	find /var/cache/pydio -name '.htaccess' -delete && \
	find /var/lib/pydio -name '.htaccess' -delete

# fix LANG
RUN echo "define(\"AJXP_LOCALE\", \"en_US.UTF-8\");" \
	>> /etc/pydio/bootstrap_conf.php

# fix for nginx, which doesn't work well with aliases
# see https://serverfault.com/questions/417357/nginx-appends-the-path-given-in-the-uri
RUN ln -s /var/lib/pydio/public/ /var/lib/pydio/public/pydio_public

# fix permissions
RUN chown -R :www /var/lib/pydio /var/cache/pydio && \
	chmod -R g+w /var/lib/pydio /var/cache/pydio

# copy folders, so we are able to sync them in our start script
# in case the user mounts in an empty folder
RUN cp -a /var/cache/pydio /var/cache/pydio-orig && \
	cp -a /var/lib/pydio /var/lib/pydio-orig

## nginx-pydio
RUN rm -rf /etc/nginx
COPY config/nginx /etc/nginx


## PHP
COPY config/php5/ext-active /etc/php/fpm-php5.6/ext-active
COPY config/php5/fpm.d /etc/php/fpm-php5.6/fpm.d

# add php to supervisord
RUN echo -e "\n\n[program:php5-fpm]\
\ncommand=/usr/bin/php-fpm -F -c /etc/php/fpm-php5.6/ -y /etc/php/fpm-php5.6/php-fpm.conf\
\nautorestart=false" >> /etc/supervisord.conf

# allow easy config file additions to php-fpm.conf
RUN echo "include=/etc/php/fpm-php5.6/fpm.d/*.conf" \
	>> /etc/php/fpm-php5.6/php-fpm.conf

EXPOSE 9000


COPY start.sh /
RUN chmod +x /start.sh

CMD /start.sh && exec /usr/bin/supervisord -n -c /etc/supervisord.conf

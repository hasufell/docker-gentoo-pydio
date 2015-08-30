FROM        hasufell/gentoo-php5.6:20150820
MAINTAINER  Julian Ospald <hasufell@gentoo.org>


# allow unstable branch for these
RUN mkdir -p /etc/paludis/keywords.conf.d && echo -e "\
\ndev-php/PEAR-HTTP_OAuth ~amd64 \
\ndev-php/PEAR-HTTP_WebDAV_Client ~amd64 \
\ndev-php/PEAR-VersionControl_Git ~amd64 \
\ndev-php/pecl-xattr ~amd64 \
" \
	>> /etc/paludis/keywords.conf.d/pydio-php.conf

# per-package USE flags
# check these with "cave show <package-name>"
RUN mkdir -p /etc/paludis/use.conf.d && echo -e "\
www-servers/nginx http http-cache ipv6 pcre ssl \
" \
	>> /etc/paludis/use.conf.d/nginx.conf

# add repository
RUN git clone --depth=1 https://github.com/hasufell/php-overlay.git /usr/php-overlay
COPY php-overlay.conf /etc/paludis/repositories/php-overlay.conf
RUN chgrp paludisbuild /dev/tty && \
	cave sync php-overlay
RUN eix-update

RUN chgrp paludisbuild /dev/tty && \
	cave resolve -z -x \
	dev-php/PEAR-Mail_mimeDecode \
	dev-php/PEAR-HTTP_OAuth \
	dev-php/PEAR-HTTP_WebDAV_Client \
	dev-php/PEAR-VersionControl_Git \
	dev-php/pecl-xattr

# update etc files... hope this doesn't screw up
RUN etc-update --automode -5

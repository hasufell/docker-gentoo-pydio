FROM        hasufell/gentoo-mysql:20150820
MAINTAINER  Julian Ospald <hasufell@gentoo.org>

## MYSQL
# contains mysql script to initialize the pydio database
COPY create_pydio_db.sql /mysql-scripts/create_pydio_db.sql

VOLUME /etc/mysql
VOLUME /mysql-scripts

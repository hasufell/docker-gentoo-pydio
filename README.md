# Gentoo based pydio

## Table of Contents

* [Getting started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Initializing for the first time](#initializing-for-the-first-time)
	* [Starting up the front proxy](#starting-up-the-front-proxy)
	* [Starting up mysql](#starting-up-mysql)
	* [Starting up pydio](#starting-up-pydio)
* [Restarting](#restarting)
  * [Restarting the backend servers](#restarting-the-backend-servers)
  * [Restarting the front proxy](#restarting-the-front-proxy)
* [Setting up pydio](#setting-up-pydio)
* [Backups](#backups)
* [Updates](#updates)
  * [Pydio and Mysql](#pydio-and-mysql)
  * [Front proxy](#front-proxy)
* [TODO](#todo)

## Getting started

__All of the commands should be executed from within the basedir
of this clone!__

### Prerequisites

SSL certificates:
* make sure you have a proper ssl certificate setup somewhere, one for each virtual host you are running (if the virtual hostname is `foo.bar.com`, then the cert must be named `foo.bar.com.crt` and the key `foo.bar.com.key`), this folder will be mapped into the proxy server

Make sure the folders you mount in from the host have group write permission
for uuid 777.

If you want to use the mailer, you need a configured mail host, possibly
using `hasufell/gentoo-dockermail` and linking the container to the
main pydio container. Then you can pass the following environment variables
when starting the main pydio container:
* `mailhub` (sets `mailhub=...` in /etc/ssmtp/ssmtp.conf)
* `AuthUser` (sets `AuthUser=...` in /etc/ssmtp/ssmtp.conf)
* `AuthPass` (sets `AuthPass=...` in /etc/ssmtp/ssmtp.conf)
And any other config variable from `/etc/ssmtp/ssmtp.conf` as an
environment variable.

### Initializing for the first time

#### Starting up the front proxy
```sh
docker pull hasufell/gentoo-nginx-proxy:latest
docker run -ti -d \
	--name=reverse-proxy \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <path-to-ssl-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/gentoo-nginx-proxy
```

#### Starting up mysql
```sh
docker pull hasufell/gentoo-mysql:latest
docker run -ti -d \
	--name=pydio-mysql \
	-e MYSQL_PASS=<mysql_admin_pass> \
	-v <mysql-data-on-host>:/var/lib/mysql \
	hasufell/gentoo-mysql
docker exec -ti \
	pydio-mysql \
	/bin/bash -c "mysqladmin -u root create pydio && echo \"grant all on pydio.* to 'pydio'@'%' identified by '<db-pw>';\" | mysql -u root"
```

#### Starting up pydio
```sh
docker build -t hasufell/gentoo-pydio .
docker run -ti -d \
	--name=pydio \
	-e VIRTUAL_HOST=<pydio-hostname> \
	--link pydio-mysql:mysql \
	-v <pydio-cache-on-host>:/var/cache/pydio \
	-v <pydio-data-on-host>:/var/lib/pydio \
	hasufell/gentoo-pydio
```

## Restarting

### Restarting the backend servers
```sh
docker stop pydio
docker stop pydio-mysql
docker rm pydio
docker rm pydio-mysql

docker run -ti -d \
	--name=pydio-mysql \
	-v <mysql-data-on-host>:/var/lib/mysql \
	hasufell/gentoo-mysql

docker run -ti -d \
	--name=pydio \
	-e VIRTUAL_HOST=<pydio-hostname> \
	--link pydio-mysql:mysql \
	-v <pydio-cache-on-host>:/var/cache/pydio \
	-v <pydio-data-on-host>:/var/lib/pydio \
	hasufell/gentoo-pydio
```

### Restarting the front proxy
```sh
docker stop reverse-proxy
docker rm reverse-proxy

docker run -ti -d \
	--name=reverse-proxy \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <path-to-ssl-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/gentoo-nginx-proxy
```

## Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When the pydio setup wizard requires you to enter the mysql server hostname,
just type in `mysql`. The pydio user and database are both `pydio` and the
pydio password is what you supplied when you set up the mysql containers.

For public links to work, log in as admin and go to the the admin settings
(top right corner, then settings). Double click on _Application Parameters_,
then on _Pydio Main Options_. Under _Main Options_ insert `https://<pydiohostname>`
into the _SERVER URL_ field.

On the same page you should also activate the PHP command line (further down
under the _Command Line_ section, activate the 'yes' checkbox at
_COMMAND-LINE ACTIVE_).

For WebDAV to work, go to _Pydio Main Options_ and activate
_ENABLE WEBDAV_, then change _SHARES URI_ to `/shares`.
This only enables global WebDAV support. Every user has to enable it for himself
too under _My Account_ and then _WEBDAV PREFERENCES_.

For the mailer to work, follow <https://pyd.io/docs/v5/workspaces/workspaces-additional-features/notifications/> and make sure you passed the correct
environment variables as described in [Prerequisites](#prerequisites).

## Backups

Just backup the mysql and pydio folders on the host which you have
mapped into the containers.

## Updates

### Pydio and Mysql

Pull the latest images:
```sh
docker pull hasufell/gentoo-mysql:latest
docker pull hasufell/gentoo-nginx:latest
```

Rebuild local images:
```sh
docker build -t hasufell/gentoo-pydio .
```

Restart containers:
```sh
docker stop pydio
docker stop pydio-mysql
docker rm pydio
docker rm pydio-mysql

docker run -ti -d \
	--name=pydio-mysql \
	-v <mysql-data-on-host>:/var/lib/mysql \
	hasufell/gentoo-mysql

docker run -ti -d \
	--name=pydio \
	-e VIRTUAL_HOST=<pydio-hostname> \
	--link pydio-mysql:mysql \
	-v <pydio-cache-on-host>:/var/cache/pydio \
	-v <pydio-data-on-host>:/var/lib/pydio \
	hasufell/gentoo-pydio
```

### Front proxy

Pull the latest image:
```sh
docker pull hasufell/gentoo-nginx-proxy:latest
```

```sh
docker stop reverse-proxy
docker rm reverse-proxy

docker run -ti -d \
	--name=reverse-proxy \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <path-to-ssl-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/gentoo-nginx-proxy
```

## TODO
* don't expose the docker socket on the machine which is exposed to the net
* allow to create multiple pydio instances on one host

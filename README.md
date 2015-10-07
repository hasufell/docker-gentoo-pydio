# Gentoo based pydio

## Getting started

__All of the commands should be executed from within the basedir
of this clone!__

### Prerequisites

SSL certificates:
* make sure you have a proper ssl certificate setup somewhere, one for each virtual host you are running (if the virtual hostname is `foo.bar.com`, then the cert must be named `foo.bar.com.crt` and the key `foo.bar.com.key`), this folder will be mapped into the proxy server

Now we just need a few more steps:
* install [docker-compose](https://docs.docker.com/compose/install/)
* create the data containers: `docker-compose -f docker-compose-data.yml up && docker-compose -f docker-compose-data-static.yml up`
* start the reverse proxy: `docker-compose -f docker-compose-reverse-proxy.yml up -d`

Make sure the folders you mount in from the host have group write permission
for uuid 777.

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
docker build -t hasufell/gentoo-mysql-pydio mysql/
docker run -ti -d \
	--name=pydio-mysql \
	-e STARTUP_SQL=/mysql-scripts/create_pydio_db.sql \
	-e PYDIO_DB_PW=<password> \
	-e MYSQL_PASS=<mysql_admin_pass> \
	-v <mysql-data-on-host>:/var/lib/mysql \
	hasufell/gentoo-mysql-pydio
```

#### Starting up pydio
```sh
docker build -t hasufell/gentoo-pydio core/
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
	hasufell/gentoo-mysql-pydio

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
pydio password is what you supplied in the environment variable `PYDIO_DB_PW`
when you set up the containers.

For public links to work, log in as admin and go to the the admin settings
(top right corner, then settings). Double click on _Application Parameters_,
then on _Pydio Main Options_. Under _Main Options_ insert `https://<pydiohostname>`
into the _SERVER URL_ field.

On the same page you should also activate the PHP command line (further down
under the _Command Line_ section, activate the 'yes' checkbox at
_COMMAND-LINE ACTIVE_).

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
docker build -t hasufell/gentoo-mysql-pydio mysql/
docker build -t hasufell/gentoo-pydio core/
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
	hasufell/gentoo-mysql-pydio

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
* outline the whole update procedure

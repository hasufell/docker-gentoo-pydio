# Gentoo based pydio with atomic nginx, mysql, php and data containers

![Missing concept image!](https://raw.githubusercontent.com/wiki/hasufell/docker-gentoo-pydio/images/concept.png)

__All of the commands should be executed from within the basedir
of this clone!__

## Configuring the containers

Copy the example settings over. This is done so you won't get merge conflicts
when you pull the latest changeset from this repository. But you could still
commit your own configs and push to some private repository. The configuration
is pretty much ready to go, unless you have specific needs.

To get started, we do:
```
cp -a ./example-config/* ./config/
```

You may want to adjust settings in the following config directories:
* `./config/nginx-pydio` (will be mapped into `/etc/nginx/` of the pydio server)
* `./config/php5/ext-active` (will be mapped into `/etc/php/fpm-php5.6/ext-active` for additional configuration on top of the default one)
* `./config/php5/fpm.d` (will be mapped into `/etc/php/fpm-php5.6/fpm.d` for additional configuration on top of the default one)
* `./config/ssl/server` (will be mapped into `/etc/nginx/certs/` for certificates)
* `./config/mysql` (holds the `create_pydio_db.sql` sql script which will be executed when the mysql server starts for the first time)

Important settings:
* make sure you have a proper ssl certificate setup in `./config/ssl/server`, one for each virtual host you are running (if the virtual hostname is `foo.bar.com`, then the cert must be named `foo.bar.com.crt` and the key `foo.bar.com.key`)
* __change the password__ in `./config/mysql/create_pydio_db.sql`! This is for accessing the mysql server

## The easy way

### Prerequisites
* install `docker-compose`
* pull the reverse proxy: `docker pull hasufell/gentoo-nginx-proxy:latest`

### Starting
```
export VIRTUAL_HOST=<pydio-hostname>
docker run -d -p 80:80 -p 443:443 -v ./config/ssl/server:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock:ro hasufell/gentoo-nginx-proxy:latest
docker-compose up
```

### Restarting
```
docker-compose restart
```

## Alternative: The hard way

### Step 1: Getting the necessary images

```sh
docker pull hasufell/gentoo-nginx-proxy:latest
docker pull hasufell/pydio-data
docker pull hasufell/gentoo-mysql:latest
docker pull hasufell/gentoo-nginx:latest
```

Now build the local pydio-php:
```sh
docker build -t pydio-php56 php56/
```

### Step 3: Creating volume data containers

We create the volume data containers. One for the mysql database which holds
the actual databases (`/var/lib/mysql`) and the mysql configuration (`/etc/mysql`), but not the server:
```sh
docker run -ti --name=mysql-data hasufell/gentoo-mysql:latest echo mysql-data
```

And one for the pydio-data which is served by nginx and php:
```sh
docker run -ti --name=pydio-data hasufell/pydio-data echo pydio-data
```

### Step 4: Creating the mysql, php and nginx containers

First of all, we start the nginx reverse proxy which automatically detects
virtual hosts and configures itself appropriately:
```sh
docker run -d -ti \
	--name=nginx-reverse \
	-v `pwd`/config/ssl/server:/etc/nginx/certs \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-p 80:80 -p 443:443 \
	hasufell/gentoo-nginx-proxy:latest
```

Now we start up the mysql server and mount our pydio mysql script into it,
which will be used for creating the pydio user and database. The server is linked
to the `mysql-data` container.
```sh
docker run -d -ti \
	--name=mysql \
	-v `pwd`/create_pydio_db.sql:/create_pydio_db.sql \
	--volumes-from mysql-data \
	-e STARTUP_SQL=/create_pydio_db.sql \
	hasufell/gentoo-mysql:latest
```

Then we start the php container, link it to the `mysql` container (server)
and connect it to the `pydio-data` volume.
```sh
docker run -d -ti \
	--name=php5.6 \
	-v `pwd`/config/php5/ext-active:/etc/php/fpm-php5.6/ext-active/ \
	-v `pwd`/config/php5/fpm.d:/etc/php/fpm-php5.6/fpm.d/ \
	--volumes-from pydio-data \
	--link mysql:mysql \
	pydio-php56
```

Now we start the nginx pydio instance, connect it to the `pydio-data` volume
and link it to both the `mysql` and `php5.6` container. If the virtual hostname
is `foo.bar.com`, we do:
```sh
docker run -d -ti \
	--name=nginx-pydio \
	-v `pwd`/config/nginx-pydio:/etc/nginx/ \
	--volumes-from pydio-data \
	--link mysql:mysql \
	--link php5.6:php56 \
	-e VIRTUAL_HOST=foo.bar.com \
	hasufell/gentoo-nginx:latest
```

## Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When the pydio setup wizard requires you to enter the mysql server hostname,
just type in `mysql`.


## TODO
* better split out the runtime data portion from the rest of the pydio stuff (e.g. files)

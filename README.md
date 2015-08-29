# Gentoo based pydio with atomic nginx, mysql, php and data containers

## Configuring the containers

Copy the example settings over. This is done so you won't get merge conflicts
when you pull the latest changeset from this repository. But you could still
commit your own configs and push to some private repository.

```
cp -a ./config/examples/nginx/* ./config/nginx/
cp -a ./config/examples/php5/* ./config/php5/
cp -a ./config/examples/ssl/* ./config/ssl/
```

You may want to adjust settings in the following config directories:
* `./config/nginx` (will be mapped into `/etc/nginx/`)
* `./config/php5` (will be mapped into `/etc/php/fpm-php5.6/`)
* `./config/ssl/certs` (will be mapped into `/etc/ssl/certs/`)
* `./config/ssl/auth` (will be mapped into `/etc/ssl/auth/`)

Important settings:
* make sure nginx and php5 run with the `www` group (should be pre-set), so that they can both access the pydio-data container
* make sure the hostnames in `config/nginx/sites-enabled/pydio.conf` are set correctly
* make sure you have a proper ssl certificate setup and nginx is configured to use it in `config/nginx/sites-enabled/pydio.conf`
* __change the password__ in `create_pydio_db.sql`! This is for accessing the mysql server

## Starting via docker-compose

### Prerequisites
* `docker-compose`

### Starting
```
docker-compose up
```

### Restarting
```
docker-compose restart
```

### Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When you configure the mysql driver in the setup wizard, then it will require
the hostname of the mysql server. In order to figure that one out, we do:
```
docker ps -f "name=pydio_mysql"
```

That may yield something like
```
CONTAINER ID        IMAGE                          COMMAND                CREATED             STATUS              PORTS               NAMES
9f6cc92a733b        hasufell/gentoo-mysql:latest   "/bin/sh -c /run.sh"   14 minutes ago      Up 10 minutes       3306/tcp            pydio_mysql_1
```

in which case we pick `pydio_mysql_1` for the hostname in the pydio mysql setup.

## Alternative: Manually starting

__All of the commands should be executed from within the basedir
of this clone!__

### Step 1: Getting the necessary images

```sh
docker pull hasufell/pydio-data
docker pull hasufell/gentoo-mysql:20150820
docker pull hasufell/gentoo-php5.6:20150820
docker pull hasufell/gentoo-nginx:20150820
```

#### Alternative: Building the images yourself

```sh
git clone --depth=1 https://github.com/hasufell/docker-pydio-data.git
docker build -t hasufell/pydio-data docker-pydio-data

git clone --depth=1 -b 20150820 https://github.com/hasufell/docker-gentoo-mysql.git
docker build -t hasufell/gentoo-mysql docker-gentoo-mysql

git clone --depth=1 -b 20150820 https://github.com/hasufell/docker-gentoo-php5.6.git
docker build -t hasufell/gentoo-php5.6 docker-gentoo-php5.6

git clone --depth=1 -b 20150820 https://github.com/hasufell/docker-gentoo-nginx.git
docker build -t hasufell/gentoo-nginx docker-gentoo-nginx
```

### Step 3: Creating volume data containers

We create the volume data containers. One for the mysql database which holds
the actual databases (`/var/lib/mysql`) and the mysql configuration (`/etc/mysql`), but not the server:
```sh
docker run -ti --name=mysql-data hasufell/gentoo-mysql:20150820 echo mysql-data
```

And one for the pydio-data which is served by nginx and php:
```sh
docker run -ti --name=pydio-data hasufell/pydio-data echo pydio-data
```

### Step 4: Creating the mysql, php and nginx containers

Now we start up the mysql server and mount our pydio mysql script into it,
which will be used for creating the pydio user and database. The server is linked
to the `mysql-data` container.
```sh
docker run -d -ti \
	--name=mysql \
	-v `pwd`/create_pydio_db.sql:/create_pydio_db.sql \
	--volumes-from mysql-data \
	-e STARTUP_SQL=/create_pydio_db.sql \
	hasufell/gentoo-mysql:20150820
```

Then we start the php container, link it to the `mysql` container (server)
and connect it to the `pydio-data` volume.
```sh
docker run -d -ti \
	--name=php5.6 \
	-v `pwd`/config/php5:/etc/php/fpm-php5.6/ \
	--volumes-from pydio-data \
	--link mysql:mysql \
	hasufell/gentoo-php5.6:20150820
```

Finally we start nginx, connect it to the `pydio-data` volume and link it to
both the `mysql` and `php5.6` container. Both ports `80` and `443` will be
mapped on the host.
```sh
docker run -d -ti \
	--name=nginx \
	-v `pwd`/config/nginx:/etc/nginx/ \
	-v `pwd`/config/ssl/certs:/etc/ssl/certs/ \
	-v `pwd`/config/ssl/auth:/etc/ssl/auth/ \
	--volumes-from pydio-data \
	-p 80:80 -p 443:443 \
	--link mysql:mysql \
	--link php5.6:php56 \
	hasufell/gentoo-nginx:20150820
```

### Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When the pydio setup wiiard requires you to enter the mysql server hostname,
just type in `mysql`.


## TODO
* better split out the runtime data portion from the rest of the pydio stuff (e.g. files)

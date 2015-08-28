# Gentoo based pydio with atomic nginx, mysql, php and data containers

__All of the commands should be executed from within the basedir
of this clone!__

## Step 1: Getting the necessary images

```sh
docker pull hasufell/pydio-data
docker pull hasufell/gentoo-mysql
docker pull hasufell/gentoo-php5.6
docker pull hasufell/gentoo-nginx
```

### Alternative: Building the images yourself

```sh
git clone --depth=1 https://github.com/hasufell/docker-pydio-data.git
cd docker-pydio-data
docker build -t hasufell/pydio-data .
cd ..

git clone --depth=1 https://github.com/hasufell/docker-gentoo-mysql.git
cd docker-gentoo-mysql
docker build -t hasufell/gentoo-mysql .
cd ..

git clone --depth=1 https://github.com/hasufell/docker-gentoo-php5.6.git
cd docker-gentoo-php5.6
docker build -t hasufell/gentoo-php5.6 .
cd ..

git clone --depth=1 https://github.com/hasufell/docker-gentoo-nginx.git
cd docker-gentoo-nginx
docker build -t hasufell/gentoo-nginx .
```

## Step 2: Configuring the containers

We may want to configure the settings in `config/php5.6` and `config/nginx`.
We have to make sure that php and nginx run with the group `www`, so that they
have both access to the pydio data files we are going to set up.

You should also __change the password__ in `create_pydio_db.sql`!

## Step 3: Creating volume data containers

We create the volume data containers. One for the mysql database which holds
the actual databases (`/var/lib/mysql`) and the mysql configuration (`/etc/mysql`), but not the server:
```sh
docker run -ti --name=mysql-data hasufell/gentoo-mysql echo mysql-data
```

And one for the pydio-data which is served by nginx and php:
```sh
docker run -ti --name=pydio-data hasufell/pydio-data echo pydio-data
```

## Step 4: Creating the mysql, php and nginx containers

Now we start up the mysql server and mount our pydio mysql script into it,
which will be used for creating the pydio user and database. The server is linked
to the `mysql-data` container.
```sh
docker run -d -ti \
	--name=mysql \
	-v `pwd`/create_pydio_db.sql:/create_pydio_db.sql \
	--volumes-from mysql-data \
	-e STARTUP_SQL=/create_pydio_db.sql \
	hasufell/gentoo-mysql
```

Then we start the php container, link it to the `mysql` container (server)
and connect it to the `pydio-data` volume.
```sh
docker run -d -ti \
	--name=php5.6 \
	-v `pwd`/config/php5/php-fpm.conf:/etc/php/fpm-php5.6/php-fpm.conf \
	--volumes-from pydio-data \
	--link mysql:mysql \
	hasufell/gentoo-php5.6
```

Finally wer start nginx, connect it to the `pydio-data` volume and link it to
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
	hasufell/gentoo-nginx
```


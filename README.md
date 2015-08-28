## Running pydio

First we pull the necessary images:
```sh
docker pull hasufell/pydio-data
docker pull hasufell/gentoo-php5.6
docker pull hasufell/gentoo-nginx
```

__All of the following commands must be executed from within the basedir
of this clone!__

Then we may want to configure these in `config/php5.6` and `config/nginx`.
We have to make sure that php and nginx run with the group `www`, so that they
have both access to the pydio data files we are going to set up.

First we create a mysql database container which holds the actual databases
(`/var/lib/mysql`) and the mysql configuration (`/etc/mysql`):
```sh
docker run -ti --name=mysql-data hasufell/gentoo-mysql echo mysql-data
```

Then we start up the mysql server and mount our pydio mysql script into it,
which we will use for creating the pydio user and database:
```sh
docker run -d -ti --name=mysql \
	-p 3306:3306 \
	-v `pwd`/create_pydio_db.sql:/create_pydio_db.sql \
	--volumes-from mysql-data \
	hasufell/gentoo-mysql
```

Then we execute the pydio sql script in the running container:
```sh
docker exec -ti mysql \
	/bin/bash -c "/usr/bin/mysql -uroot < /create_pydio_db.sql"
```

Now we create the data volume that holds the pydio data:
```sh
docker run -ti --name=pydio-data hasufell/pydio-data echo pydio-data
```

And now we can fire up both the php and nginx containers while connecting
them to the pydio-data container and linking php with nginx.
```sh
docker run -d -ti --name=php5.6 -v \
	`pwd`/config/php5/php-fpm.conf:/etc/php/fpm-php5.6/php-fpm.conf \
	--volumes-from pydio-data \
	--link mysql:mysql \
	hasufell/gentoo-php5.6

docker run -d --name=nginx -ti -v `pwd`/config/nginx:/etc/nginx/ -v \
	`pwd`/config/ssl/certs:/etc/ssl/certs/ \
	-v `pwd`/config/ssl/auth:/etc/ssl/auth/ \
	--volumes-from pydio-data -p 80:80 -p 443:443 \
	--link mysql:mysql \
	--link php5.6:php56 \
	hasufell/gentoo-nginx
```


## Running pydio

First we pull the necessary images:
```
docker pull hasufell/pydio-data
docker pull hasufell/gentoo-php5.6
docker pull hasufell/gentoo-nginx
```

Then we may want to configure these in `config/php5.6` and `config/nginx`.
We have to make sure that php and nginx run with the group `www`, so that they
have both access to the pydio data files we are going to set up.

Now we create the data volume that holds the pydio data:
```
docker run -ti --name=pydio-data hasufell/pydio-data echo pydio-data
```

And now we can fire up both the php and nginx containers while connecting
them to the pydio-data container and linking php with nginx.
```
docker run -d -ti --name=php5.6 -v `pwd`/config/php5/php-fpm.conf:/etc/php/fpm-php5.6/php-fpm.conf --volumes-from pydio-data hasufell/gentoo-php5.6

docker run -d --name=nginx -ti -v `pwd`/config/nginx:/etc/nginx/ -v `pwd`/config/ssl/certs:/etc/ssl/certs/ -v `pwd`/config/ssl/auth:/etc/ssl/auth/ --volumes-from pydio-data -p 80:80 -p 443:443 --link php5.6:php56 hasufell/gentoo-nginx
```

## TODO

* mysql

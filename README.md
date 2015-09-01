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

## Getting started

### Prerequisites
* install [docker-compose](https://docs.docker.com/compose/install/)
* pull the reverse proxy: `docker pull hasufell/gentoo-nginx-proxy:20150820`
* create the config containers: `docker-compose -f docker-compose-config.yml up`
* create the data containers: `docker-compose -f docker-compose-data.yml up`
* start the reverse proxy: `docker-compose -f docker-compose-reverse-proxy.yml up`

### Starting
```
export VIRTUAL_HOST=<pydio-hostname>
docker-compose up -d
```

### Restarting
```
docker-compose stop
docker-compose rm
docker-compose start
```

### Recreating the config
```
docker-compose stop
docker-compose -f docker-compose-config.yml rm
docker-compose -f docker-compose-config.yml up
docker-compose start
```


## Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When the pydio setup wizard requires you to enter the mysql server hostname,
just type in `mysql`.


## TODO
* better split out the runtime data portion from the rest of the pydio stuff (e.g. files)

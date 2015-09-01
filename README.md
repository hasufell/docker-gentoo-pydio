# Gentoo based pydio with atomic nginx, mysql, php and data containers

![Missing concept image!](https://raw.githubusercontent.com/wiki/hasufell/docker-gentoo-pydio/images/concept.png)

## Getting started

__All of the commands should be executed from within the basedir
of this clone!__

### Prerequisites

SSL certificates:
* make sure you have a proper ssl certificate setup in `./nginx-proxy/ssl/server`, one for each virtual host you are running (if the virtual hostname is `foo.bar.com`, then the cert must be named `foo.bar.com.crt` and the key `foo.bar.com.key`)

Now we just need a few more steps:
* install [docker-compose](https://docs.docker.com/compose/install/)
* create the data containers: `docker-compose -f docker-compose-data.yml up`
* start the reverse proxy: `docker-compose -f docker-compose-reverse-proxy.yml up -d`

### Initializing for the first time
```sh
STARTUP_SQL=/mysql-scripts/create_pydio_db.sql \
	VIRTUAL_HOST=<pydio-hostname> \
	PYDIO_DB_PW=<password> \
	MYSQL_PASS=<mysql_admin_pass> \
	docker-compose up -d
```

### Restarting the backend servers
```sh
docker-compose stop
docker-compose rm
MYSQL_PASS=<mysql_admin_pass> \
	VIRTUAL_HOST=<pydio-hostname> \
	docker-compose up -d
```

### Restarting the front proxy
```sh
docker-compose -f docker-compose-reverse-proxy.yml stop
docker-compose -f docker-compose-reverse-proxy.yml rm
docker-compose -f docker-compose-reverse-proxy.yml up -d
```

## Setting up pydio

Now use a browser and access the site, e.g. `https://www.example.net` if
that is your nginx hostname. You will go through the setup wizard.

When the pydio setup wizard requires you to enter the mysql server hostname,
just type in `mysql`.

For public links to work, log in as admin and go to the the admin settings
(top right corner, then settings). Double click on _Application Parameters_,
then on _Pydio Main Options_. Under _Main Options_ insert __https://\<pydiohostname\>__
into the _SERVER URL_ field.
On the same page you should also activate the PHP command line (further down
under the _Command Line_ section, activate the 'yes' checkbox at
_COMMAND-LINE ACTIVE_).


## TODO
* better split out the runtime data portion from the rest of the pydio stuff (e.g. files)

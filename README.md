# Gentoo based pydio with atomic nginx, mysql, php and data containers

![Missing concept image!](https://raw.githubusercontent.com/wiki/hasufell/docker-gentoo-pydio/images/concept.png)

## Getting started

__All of the commands should be executed from within the basedir
of this clone!__

### Prerequisites

SSL certificates:
* make sure you have a proper ssl certificate setup in `./nginx-proxy/ssl/server`, one for each virtual host you are running (if the virtual hostname is `foo.bar.com`, then the cert must be named `foo.bar.com.crt` and the key `foo.bar.com.key`), this folder will be mapped into the proxy server

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

### Creating backups

We can simply create backups of all our data containers
(in this example they will be dropped into the current directory):
```sh
bin/create-backup.sh
```
This will drop 2 files into the current working dir, e.g.:
```
  pydio-data-backup-2015-09-02-11:53.tar.xz
  mysql-data-backup-2015-09-02-11:53.tar.xz

```

### Restore from backup

Suppose we have the backups in `pydio-data-backup-2015-09-02-11:53.tar.xz` and
`mysql-data-backup-2015-09-02-11:53.tar.xz` in the current directory and want
to add that data on a new host. First we follow the
[Prerequisites](README.md#prerequisites) section as usual. But we do
__not__ follow the
[regular initialization](README.md#initializing-for-the-first-time).
Instead, we run the following command:
```sh
bin/restore-backup.sh \
	pydio-data-backup-2015-09-02-11:02.tar.xz \
	mysql-data-backup-2015-09-02-11:02.tar.xz
```

And now we _initialize_ the containers:
```sh
VIRTUAL_HOST=<pydio-hostname> \
	docker-compose up -d
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
then on _Pydio Main Options_. Under _Main Options_ insert __https://\<pydiohostname\>__
into the _SERVER URL_ field.
On the same page you should also activate the PHP command line (further down
under the _Command Line_ section, activate the 'yes' checkbox at
_COMMAND-LINE ACTIVE_).


## TODO
* better split out the runtime data portion from the rest of the pydio stuff (e.g. files)

#!/bin/bash

if [[ ! -e /var/lib/pydio/public/index.html ]] ; then
	mkdir -p /var/lib/pydio
	chown -R :www /var/lib/pydio
	chmod -R g+w /var/lib/pydio
	rsync -a /var/lib/pydio-orig/* /var/lib/pydio/
fi

if [[ ! -e /var/cache/pydio/index.html ]] ; then
	mkdir -p /var/cache/pydio
	chown -R :www /var/cache/pydio/
	chmod -R g+w /var/cache/pydio/
	rsync -a /var/cache/pydio-orig/* /var/cache/pydio/
fi

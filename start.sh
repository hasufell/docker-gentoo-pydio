#!/bin/bash

dir_is_empty() {
	# usage:
	#  dir_is_empty <some-dir>
	#
	# returns 2 if the dir does not even exist
	# returns 1 if the dir is not empty
	# returns 0 (success) if the dir exists and is empty

	local dir=$1
	local files

	if [[ ! -e ${dir} ]] ; then
		return 2
	fi

	shopt -s nullglob dotglob     # To include hidden files
	files=( "${dir}"/* )
	shopt -u nullglob dotglob

	if [[ ${#files[@]} -eq 0 ]]; then
		return 0
	else
		return 1
	fi

}

sed_ssmtp() {
	local i
	local args=(
		root
		mailhub
		AuthUser
		AuthPass
		UseSTARTTLS
		UseTLS
		TLSCert
		FromLineOverride
	)

	for i in ${args[@]} ; do
		if [[ ${!i} ]] ; then
			if $(grep -q "^${i}=.*" /etc/ssmtp/ssmtp.conf) ; then
				sed -i -e \
					"s/^${i}=.*$/${i}=${!i}/" \
					/etc/ssmtp/ssmtp.conf
			else
				echo "${i}=${!i}" >> /etc/ssmtp/ssmtp.conf
			fi
		fi
	done
}


# if folders are empty, they are probably mounted in from the host,
# so we sync them

if dir_is_empty /var/lib/pydio ; then
	echo ""
	echo "Syncing /var/lib/pydio"
	echo ""

	chown -R :www /var/lib/pydio
	chmod -R g+w /var/lib/pydio
	rsync -a /var/lib/pydio-orig/* /var/lib/pydio/
fi

if dir_is_empty /var/cache/pydio ; then
	echo ""
	echo "Syncing /var/cache/pydio"
	echo ""

	chown -R :www /var/cache/pydio/
	chmod -R g+w /var/cache/pydio/
	rsync -a /var/cache/pydio-orig/* /var/cache/pydio/
fi

sed_ssmtp


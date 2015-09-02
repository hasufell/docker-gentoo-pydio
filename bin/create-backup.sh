#!/bin/bash

date="$(date -u +'%Y-%m-%d-%H:%M')"
outfile1=pydio-data-backup-${date}.tar
outfile2=mysql-data-backup-${date}.tar


usage() {
cat << EOF

Usage: create-backup.sh [ options ]

Creates two backup files of both pydio-data and
mysql-data and drops them with a timestamp in the
filename into the CURRENT DIRECTORY, e.g.:

  ${outfile1}.xz
  ${outfile2}.xz

options:
  --help, -h       Show help
EOF
	exit ${1:-0}
}

die() {
	echo $@
	exit 1
}


if [[ $# > 0 ]] ; then
	usage
fi



## pydio-data backup

[[ -e ${outfile1} ]] && die "file \"${outfile1}\" does already exist!"

docker run \
	--volumes-from pydiodata \
	-v "`pwd`":/backup \
	hasufell/pydio-data:6.0.8 \
	sh -c "tar cvf /backup/${outfile1} /var/www/pydio" \
	|| die "failed to create backup \"${outfile1}\""

# busybox image does not support 'tar --xz'
xz -9 ./"${outfile1}" || die "failed to compress \"${outfile1}\""


## mysql-data backup

[[ -e ${outfile2} ]] && die "file \"${outfile2}\" does already exist!"

docker run \
	--volumes-from mysqldata \
	-v "`pwd`":/backup \
	hasufell/gentoo-mysql:20150820 \
	sh -c "tar Jcvf /backup/${outfile2}.xz /var/lib/mysql" \
	|| die "failed to create backup \"${outfile2}\""


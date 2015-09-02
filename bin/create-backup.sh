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
	--name="${outfile1/:/_}" \
	--volumes-from pydiodata \
	hasufell/pydio-data:latest \
	sh -c "tar cvf /${outfile1} /var/www/pydio &>/dev/null && cat /${outfile1}" \
	> ./${outfile1} \
	|| die "failed to create backup \"${outfile1}\""

# busybox image does not support 'tar --xz'
xz -9 ./"${outfile1}" || die "failed to compress \"${outfile1}\""

docker rm ${outfile1/:/_} > /dev/null || die "failed to remove temporary docker container ${outfile1/:/_}"

echo "created backup: ${outfile1}.xz"


## mysql-data backup

[[ -e ${outfile2} ]] && die "file \"${outfile2}\" does already exist!"

docker run \
	--name="${outfile2/:/_}" \
	--volumes-from mysqldata \
	hasufell/gentoo-mysql:latest \
	sh -c "tar Jcvf /${outfile2}.xz /var/lib/mysql &>/dev/null && cat /${outfile2}.xz" \
	> ./${outfile2}.xz \
	|| die "failed to create backup \"${outfile2}\""

docker rm ${outfile2/:/_} > /dev/null || die "failed to remove temporary docker container ${outfile2/:/_}"

echo "created backup: ${outfile2}.xz"

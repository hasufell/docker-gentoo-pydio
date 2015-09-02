#!/bin/bash

inputfile1=$1
inputfile2=$2

usage() {
cat << EOF

Usage: restore-backup.sh [ options ] <pydio-data-backup-file> <mysql-data-backup-file>

Restores from the backup files <pydio-data-backup-file> and
<mysql-data-backup-file> respectively.

options:
  --help, -h       Show help
EOF
	exit ${1:-0}
}

die() {
	echo $@
	exit 1
}


while [[ $# > 0 ]] ; do
	case "$1" in
		--help|-h)
			usage ;;
		-*)
			echo "!!! Error: Unknown option ${1}. See: restore-backup.sh --help"
			exit 1 ;;

		*)
			break ;;
	esac
done

if [[ -z "$*" ]] ; then
	echo "!!! Error: You must supply the input filenames !!!"
	exit 1
fi



## pydio-data backup

[[ -e ${inputfile1} ]] || die "file \"${inputfile1}\" does not exist!"
[[ ${inputfile1} =~ '/' ]] && die "file \"${inputfile1}\" is a path, aborting!"
[[ ${inputfile1} =~ 'pydio-data-backup' ]] || die "file \"${inputfile1}\" does not appear to be a pydio-data backup!"


xz -d --stdout ./"${inputfile1}" > ./"${inputfile1%.xz}" || die "failed to unpack \"${inputfile1}\""

docker run \
	--name="${inputfile1/:/_}" \
	--volumes-from pydiodata \
	-v "`pwd`":/backup \
	hasufell/pydio-data:latest \
	sh -c "rm -rf /var/www/pydio/* && tar -C / -xvf /backup/${inputfile1%.xz}" \
	|| die "failed to restore backup from ${inputfile1}!"

rm -v ./"${inputfile1%.xz}" || die "failed to remove temporary file \"${inputfile1%.xz}\""
docker rm ${inputfile1/:/_} > /dev/null || die "failed to remove temporary docker container ${inputfile1/:/_}"

echo "restored backup: ${inputfile1}"


## mysql-data backup

[[ -e ${inputfile2} ]] || die "file \"${inputfile2}\" does not exist!"
[[ ${inputfile2} =~ '/' ]] && die "file \"${inputfile2}\" is a path, aborting!"
[[ ${inputfile2} =~ 'mysql-data-backup' ]] || die "file \"${inputfile2}\" does not appear to be a mysql-data backup!"

docker run \
	--name="${inputfile2/:/_}" \
	--volumes-from mysqldata \
	-v "`pwd`":/backup \
	hasufell/gentoo-mysql:latest \
	sh -c "rm -rf /var/lib/mysql/* && tar -C / -Jxvf /backup/${inputfile2}" \
	|| die "failed to restore backup from \"${inputfile2}\"!"

docker rm ${inputfile2/:/_} > /dev/null || die "failed to remove temporary docker container ${inputfile2/:/_}"

echo "restored backup: ${inputfile2}"

#!/bin/bash

inputfile1=$1
inputfile2=$2

usage() {
cat << EOF

Usage: restore-backup.sh [ options ] <pydio-data-backup-file> <mysql-data-backup-file>

Restores from the backup files <pydio-data-backup-file> and
<mysql-data-backup-file> respectively.

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
	--volumes-from pydiodata \
	-v "`pwd`":/backup \
	hasufell/pydio-data:6.0.8 \
	sh -c "rm -rf /var/www/pydio/* && tar -C / -xvf /backup/${inputfile1%.xz}" \
	|| die "failed to restore backup from ${inputfile1}!"

rm -v ./"${inputfile1%.xz}" || die "failed to remove temporary file \"${inputfile1%.xz}\""


## mysql-data backup

[[ -e ${inputfile2} ]] || die "file \"${inputfile2}\" does not exist!"
[[ ${inputfile2} =~ '/' ]] && die "file \"${inputfile2}\" is a path, aborting!"
[[ ${inputfile2} =~ 'mysql-data-backup' ]] || die "file \"${inputfile2}\" does not appear to be a mysql-data backup!"

docker run \
	--volumes-from mysqldata \
	-v "`pwd`":/backup \
	hasufell/gentoo-mysql:20150820 \
	sh -c "rm -rf /var/lib/mysql/* && tar -C / -Jxvf /backup/${inputfile2}" \
	|| die "failed to restore backup from \"${inputfile2}\"!"


#!/bin/bash

cloud="${UPLOAD_URL:-}"

# auto upload 7z+pass file/dir to fileserver
# accepts multi arguments
#
# 7z install: sudo apt install -y p7zip-full
#
# examples:
#		upload file.txt
#		upload ./some/dir
#		upload file.txt ./some/dir other.txt ./any/dir

die() { echo "$@"; exit 1; }
upload() {
	local n b ext archives archived archive SIZE
	[ -z "$1" ] && echo Usage: "`basename $0`" [dir1] [dir2] [file1] [file2] ... && exit 0
	n=
	for i in "$@"; do
	  b="$(basename "`realpath $i`")"
		ext="${i##*.}"
		archives="7z gz bz2 zip tgz tar tbz tbz2 rar"
		shopt -s nocasematch
		case "${archives[@]}" in  *"$ext"*) archived=1 ;; *) archived= ;; esac
		[ -z "$n" ] || echo
		[ -f "$i" -a ! -s "$i" ] && echo "skipping empty file $i" && continue
		if [ "`basename "$0"`" == "uploadz" ] && [ -f "$i" ] && [ -z "$archived" ] || [ -d "$i" ]; then
			if which 7z >/dev/null 2>&1; then
				unk=
			else
				echo No 7z in PATH detected! Please install 7z
				echo apt install -y p7zip-full
				exit 1
			fi
			pass="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
			archive="$b.___.7z"
			trap 'rm -f "'"$archive"'" && trap - SIGINT' SIGINT
			NUMFILES="`find $i -type f | wc -l`"
			sub_files=files
			if [ "$NUMFILES" = 1 ]; then
				sub_files=file
			fi
			7z a -bb0 -bd -bt -y -p$pass -bso0 "$archive" "$i" && \
			SIZE=`du -h "$archive" |awk '{print $1}'|sed -r 's/\.0+([^0-9])/\1/'` && \
			curl -#T "$archive" "$cloud/$b.7z" && echo "$b.7z $SIZE, pass: $pass"
			[ -f "$archive" ] && rm -f "$archive"
			trap - SIGINT
		elif test -f "$i"; then
			SIZE=`du -h "$i" |awk '{print $1}'|sed -r 's/\.0+([^0-9])/\1/'`
			curl -#T "$i" "$cloud/$b" | cat && echo "$b $SIZE"
		else
			echo "Error, please provide file or dir!"
		fi
		n=1
	done
}

upload "$@"

# EWID
LOGLEVEL=${LOGLEVEL=W}

log() {
	ll=$1
	if [ $LOGLEVEL == I ]; then
		if [[ "D" == *$ll* ]]; then
			return
		fi
	elif [ $LOGLEVEL == W ]; then
		if [[ "DI" == *$ll* ]]; then
			return
		fi
	elif [ $LOGLEVEL == E ]; then
		if [[ "DIW" == *$ll* ]]; then
			return
		fi
	fi
	echo $@
}

load_config() {
	if [ -e $(dirname "$0")/config.$HOSTNAME ]; then
		log I loading config $(dirname "$0")/config.$HOSTNAME
		source $(dirname "$0")/config.$HOSTNAME
	else
		log I loading config $(dirname "$0")/config
		source $(dirname "$0")/config
	fi
}

get_dir_and_file() {
	if [ ${1:0:1} == '/' ]; then
		dir=$(dirname "$1")
		file=$(basename "$1")
	else
		mf=$PWD/$1
		dir=$(dirname "$mf")
		file=$(basename "$mf")
	fi
}

resolve_home_dir() {
	if [[ ! ("$(realpath --relative-to $HOME $dir)" =~ "../") ]]; then
		tdir=HOME/$(realpath --relative-to $HOME $dir)
	else
		tdir=$dir
	fi
	log D dir in target is $tdir
}

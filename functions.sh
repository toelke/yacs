# EWID
LOGLEVEL=${LOGLEVEL=W}

log() {
	ll=$1
	shift
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
	echo $ll: $@
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

deyacsify() {
	load_classes
	SRC=$DATA/$tdir/$file
	# SRC will be changed if a class-file is used
	ORIG_SRC=$SRC
	DEST=$dir/$file
	if [ ! -d "$SRC" ]; then
		log E $DEST is not under yacss control, so I cannot do anything for it
		exit 1
	fi
	SRC=$(find_class_file)
	PRE=$(find_executable_class_file pre)
	INSTEAD=$(find_executable_class_file instead)
	POST=$(find_executable_class_file post)

	if [ -z "$SRC" -a -z "$INSTEAD" ]; then
		if [ $UPDATE_ONLY -eq 1 ]; then
			log I $DEST does not exist for these classes
			exit 0
		else
			log E $DEST does not exist for these classes
			exit 1
		fi
	fi

	if [ -L $DEST ]; then
		if [ $(readlink $DEST) == $SRC ]; then
			log I link already current
			exit 0
		fi
	fi

	if [ -n "$INSTEAD" ]; then
		# FIXME
		export SRC=$($MKTEMP)
		$INSTEAD > $SRC
	fi

	[ -n "$PRE" ] && $PRE
	$LN -svf $SRC $DEST
	[ -n "$POST" ] && $POST
}

function load_classes {
	export CLASSES=''

	if [ -e $DATA/classes.$HOSTNAME ]; then
	   CLASSES=$(cat $DATA/classes.$HOSTNAME)
	fi
}

function find_class_file {
	for i in $HOSTNAME $CLASSES DEFAULT; do
		if [ -e $ORIG_SRC/$i ]; then
		   echo $ORIG_SRC/$i
		   return
	   fi
   done
}

function find_executable_class_file {
	for i in $HOSTNAME $CLASSES DEFAULT; do
		if [ -x $ORIG_SRC/$1.$i ]; then
		   echo $ORIG_SRC/$1.$i
		   return
	   fi
   done
}

function update_all {
	find $DATA -type d | grep -v '/\.git/' | sort -r | awk 'index(a,$0)!=1{a=$0;print}' | sort | while read line; do
		target=$(echo ${line#$DATA} | sed -e "s,HOME,$HOME,")
		log W yacsifying $target
		$(dirname $0)/yacsify --update-only $target
	done
}

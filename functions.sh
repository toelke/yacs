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
	echo "$ll": $@
}

load_config() {
	real_file=$(realpath "$0")
	if [ -e $(dirname "$real_file")/config.$HOSTNAME ]; then
		log I loading config $(dirname "$real_file")/config.$HOSTNAME
		source $(dirname "$real_file")/config.$HOSTNAME
	else
		log I loading config $(dirname "$real_file")/config
		source $(dirname "$real_file")/config
	fi
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

# ====== ng from here

function copy_out_of_yacs {
	echo copying "$1" to "$2" while handling permissions
	mkdir -pv "$(dirname "$2")"
	$CP -v "$1" "$2"
	mode=$(sed -e "s/CURRENT_USER/$USER/;s/CURRENT_GROUP/$(id -gn)/" < "$(dirname "$1")/file-mode")
	$CHOWN -v ${mode% *} "$2"
	$CHMOD -v ${mode#* } "$2"
}

function copy_into_yacs {
	log D copying "$1" into yacs as "$2"
	mkdir -pv "$(dirname "$2")"
	$CP -v "$1" "$2"
	$STAT -c "%U:%G %a" "$1" | sed -e "s/^$USER:/CURRENT_USER:/;s/:$(id -gn) /:CURRENT_GROUP /" > "$(dirname "$2")/file-mode"
}

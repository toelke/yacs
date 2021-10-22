#!/bin/bash -eu

# EWID
LOGLEVEL=${LOGLEVEL=W}

BASE=$(realpath $(dirname $0))

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

handleOneDir() {
	local base=$(realpath --relative-to=$BASE $1)
	log D handling one dir $base
	pushd $BASE/$base > /dev/null
	ls -1A | while read candidate; do
		[ $candidate == ".git" ] && continue
		[ $candidate == "roll-out.sh" ] && continue
		[[ $candidate =~ ".swp" ]] && continue

		log D candidate is $base/$candidate

		if [ -f $candidate ]; then
			if [ -L ~/$base/$candidate ]; then
				if [ $(readlink ~/$base/$candidate) != $BASE/$base/$candidate ]; then
					log W not overwriting foreign link ~/$base/$candidate -\> $(readlink ~/$candidate) with -\> $BASE/$base/$candidate
				else
					log D $base/$candidate is already rolled out
				fi
			elif [ -e ~/$base/$candidate ]; then
				log W not overwriting normal file $base/$candidate
			else
				log I linking $base/$candidate
				mkdir -p ~/$base
				ln -s $BASE/$base/$candidate ~/$base/$candidate
			fi
		elif [ -d $candidate ]; then
			log D handling dir $candidate
			handleOneDir $candidate < /dev/null
		fi
	done
	popd > /dev/null
}

log I BASE is $BASE
handleOneDir $BASE

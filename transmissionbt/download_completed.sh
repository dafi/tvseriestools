#!/bin/bash
# This script must be called by Transmission after the file download is completed
# The downloaded file name is prettified, any containing directory is deleted
# The torrent is removed from the list

# default values must be overridden on env_shell.conf
TRANSMISSION_SERVER="--auth USER:PWD"
LOG_FILE="$TR_TORRENT_DIR/torrent_completed.log"
CONFIG_FILE=`dirname $0`/env_shell.conf

if [ ! -e $CONFIG_FILE ]; then
	echo $CONFIG_FILE not found
	exit 1
fi
. $CONFIG_FILE

function remove_completed {
	TORRENTLIST=`transmission-remote $TRANSMISSION_SERVER --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=" " --fields=1`

	for TORRENTID in $TORRENTLIST
	do
		# echo Processing : $TORRENTID
    	# check if torrent download is completed
	    DL_COMPLETED=`transmission-remote $TRANSMISSION_SERVER --torrent $TORRENTID --info | grep "Percent Done: 100%"`
    	if [ "$DL_COMPLETED" ] ; then
        	# move the files and remove the torrent from Transmission
        	# echo "Torrent #$TORRENTID is completed"
        	# echo "Removing torrent from list"
        	transmission-remote $TRANSMISSION_SERVER --torrent $TORRENTID --remove
    	else
        	echo "Torrent #$TORRENTID is not completed. Ignoring."
    	fi
	done
}

function delete_file {
	uname="$(uname)"
	# under macos move to trash
	if [ "Darwin" = "${uname}" ]; then
		osascript -e "tell application \"Finder\" to delete POSIX file \"$TR_TORRENT_DIR/$TR_TORRENT_NAME\"" &>/dev/null
	else
		rm -Rf "$TR_TORRENT_DIR/$TR_TORRENT_NAME"
	fi
}

if [ "$TR_TORRENT_DIR" != "" ] ; then
	mkdir -p `dirname $LOG_FILE`

	logger -s Renaming $TR_TORRENT_DIR/$TR_TORRENT_NAME >>$LOG_FILE 2>&1
	`dirname $0`/../prettify.rb "$TR_TORRENT_DIR/$TR_TORRENT_NAME" >>$LOG_FILE 2>&1
	if [ -d "$TR_TORRENT_DIR/$TR_TORRENT_NAME" ]
	then
		found=`find "$TR_TORRENT_DIR/$TR_TORRENT_NAME" -maxdepth 1 -type f -name "*.mp4" -o -name "*.avi" -o -name "*.mkv"`
		if [ -n "$found" ]
		then
			mv "$found" "$TR_TORRENT_DIR"
			delete_file
			remove_completed
		fi		
	fi
fi

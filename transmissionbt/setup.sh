#!/usr/bin/env bash
# Setup the directories used to download torrent with transmission daemon

if [ $# -lt 1 ]
then
    echo "Root path mandatory (eg /mnt/mymedia)"
    exit 1
fi

MEDIA_LIBRARY=$1
DAEMON_GROUP=debian-transmission

# the torrent subtree is used by transmission
mkdir -p $MEDIA_LIBRARY/{movies/temp,torrent/progress,torrent/watch}

# Allow transmission daemon to write to the directories created above
chgrp -R $DAEMON_GROUP $MEDIA_LIBRARY

# grant 'other' to write otherwise transmission daemon
# can't remove .torrent files
chmod 777 -R $MEDIA_LIBRARY/torrent/
chmod 770 -R $MEDIA_LIBRARY/movies/temp/	

echo Add `whoami` user to $DAEMON_GROUP group
sudo usermod -a -G $DAEMON_GROUP `whoami`

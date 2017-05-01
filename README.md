TV Series Tools
===============

Ruby scripts to

- format tv series file names
- download subtitles

These scripts was originally written in nodejs but due to annoying problems with async functions are totally rewritten in ruby

See [pretty-format-movie-filename](https://github.com/dafi/pretty-format-movie-filename) for nodejs version

## Prerequisites


	# should be needed to install nokogiri
	sudo apt-get install ruby-dev


	gem install nokogiri (*)
	gem install rubyzip
	gem install open_uri_redirections

(*) nokogiri can fail to install if `xv` is installed, see [more](https://github.com/sparklemotion/nokogiri/issues/1483)

### Raspberry and Transmission daemon

The daemon configuration is located at `/etc/transmission-daemon/settings.json`

Stop transmission before edit the configuration because modifications may be lost after saving (`reload` seems not working)

 	sudo service transmission-daemon stop
 	
	sudo service transmission-daemon start
  
#### Main config settings

	{
    "download-dir": "",
	"incomplete-dir": "",
    "incomplete-dir-enabled": true,
    "script-torrent-done-enabled": true,
    "script-torrent-done-filename": "",
    "watch-dir": "",
    "watch-dir-enabled": true
    }

#### Setup Raspberry env

Run the script `transmissionbt/setup.sh`  
A very useful [post](http://www.robertsetiadi.com/installing-transmission-in-raspberry-pi/)

#### Monitor file changes

The subtitles may automatically be extracted and renamed when copied to the download directory.

File changes are detected using [`incron`](https://www.howtoforge.com/tutorial/trigger-commands-on-file-or-directory-changes-with-incron/) but it (or better inotify) doesn't completely work on samba mount indeed  created directories are handled but files don't

    sudo apt-get install incron
    
Do not use tabs to separated fields when edit `incrontab -e`, use whitespaces  
Do not forget to add users to `/etc/incron.allow`

The flag `IN_CREATE` is sufficient to monitor the directory
    
#### Log
As usual check errors with `cat /var/log/syslog`    

### Add user to transmission daemon group
The the script `transmissionbt/setup.sh` already does it but more details are present [here](https://help.ubuntu.com/community/TransmissionHowTo#Configure_Users_and_Permissions)

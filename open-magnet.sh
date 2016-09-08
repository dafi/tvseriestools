#!/bin/bash
# Open the magnet link

if [[ "$(uname)" = 'Darwin' ]]; then
	open $1
else
	echo use rpc
fi

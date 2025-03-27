#!/bin/sh

if [ ! -z "$RELEASE" ] ; then
	echo "\"$RELEASE\"" | tr -d "v"

else
	echo "\"1.$(date +%Y%j)\""

fi


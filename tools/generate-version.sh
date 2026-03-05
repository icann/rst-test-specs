#!/bin/bash

if [ ! -z "$RELEASE" ] ; then
	echo "\"$RELEASE\"" | tr -d "v"

else
	echo "\"3.$(date +%Y%j)\""

fi


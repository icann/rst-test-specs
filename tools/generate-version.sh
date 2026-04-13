#!/bin/bash

if [ ! -z "$RELEASE" ] ; then
    echo "Generating version using \$RELEASE environment variable (${RELEASE})" > /dev/stderr
	echo "\"$RELEASE\"" | tr -d "v"
    exit
fi

BRANCH="$(git branch | grep '^\*' | cut -b 3- | tr -d v)"

if [[ "$BRANCH" =~ ^[0-9]+(\.[0-9]+)+$ ]] ; then
    echo "Generating version using the current git branch" > /dev/stderr
    echo "$BRANCH"
    exit
fi

echo "Generating version using the current date" > /dev/stderr
echo "\"3.$(date +%Y%j)\""

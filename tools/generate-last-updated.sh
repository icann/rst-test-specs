#!/bin/sh

if [ ! -z "$RELEASE" ] ; then
    git log -1 --format=%ad --date=format:%Y-%m-%d "$RELEASE"

else
    date +%Y-%m-%d

fi

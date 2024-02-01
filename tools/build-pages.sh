#!/bin/sh
DIR="$(dirname "$(dirname "$(realpath "$0")")")"
SITEDIR="$DIR/_site"
cd $DIR

mkdir $SITEDIR

pandoc --from markdown \
    --to html \
    --standalone \
    --metadata title="" \
    --output="$SITEDIR/index.html" \
    README.md

BRANCH="$(git branch --show-current)" perl -pi -e 's!</head>!<base href="https://github.com/icann/rst-test-specs/tree/$ENV{BRANCH}/"></head>!' _site/index.html

make all

mv rst.json rst-test-specs.html rst-test-specs.json rst-test-specs.yaml "$SITEDIR/"
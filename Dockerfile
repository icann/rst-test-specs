FROM alpine:latest

RUN apk update

RUN apk add make gcc musl-dev perl perl-file-slurp perl-json-xs \
    perl-yaml perl-yaml-libyaml perl-text-unidecode perl-xml-libxml \
    perl-uri perl-app-cpanminus pandoc git graphviz perl-dev curl

RUN cpanm --notest HTML::Tiny GraphViz2 JSON::Schema

RUN <<END
wget -qO - https://github.com/logological/gpp/releases/download/2.28/gpp-2.28.tar.bz2 | tar xj
cd gpp-2.28
./configure --quiet
make install
rm -rf ../gpp-2.28
END

all:
	gpp -x rst-test-specs.yaml.in > rst-test-specs.yaml
	perl -MYAML::XS -MJSON::XS -e 'print JSON::XS->new->utf8->canonical->pretty->encode(YAML::XS::LoadFile("./rst-test-specs.yaml"))' > rst-test-specs.json
	perl -Itools/perl tools/generate-html.pl rst-test-specs.yaml > rst-test-specs.html

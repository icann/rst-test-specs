all:
	gpp -x rst-test-specs.yaml.in > rst-test-specs.yaml
	perl -Itools/perl tools/generate-html.pl rst-test-specs.yaml > rst-test-specs.html

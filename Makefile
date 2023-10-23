all:
	perl -Itools/perl tools/generate-html.pl rst-test-specs.yaml > rst-test-specs.html
	
all:
	perl -Itools/perl tools/2.generate-html.pl rst-test-specs.yaml > rst-test-specs.html
	
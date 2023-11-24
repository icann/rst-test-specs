src = rst-test-specs
all: export PERL5LIB=./tools/perl
all: yaml json html

yaml:
	@echo "Compiling YAML..."
	@gpp -x $(src).yaml.in > $(src).yaml
	@echo wrote $(src).yaml

json:
	@echo "Compiling JSON..."
	@perl -MYAML::XS -MJSON::XS -e 'print JSON::XS->new->utf8->canonical->pretty->encode(YAML::XS::LoadFile("./$(src).yaml"))' > $(src).json
	@echo wrote $(src).json

html:
	@echo "Compiling HTML..."
	@perl tools/generate-html.pl $(src).yaml > $(src).html
	@echo wrote $(src).html

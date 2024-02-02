include .env
src = rst-test-specs
ZM_DIR="zonemaster/zonemaster-$(ZONEMASTER_VERSION)"

all: export PERL5LIB=./tools/perl
all: zonemaster-profile includes yaml lint json html

zonemaster-profile:
	@echo Generating Zonemaster profile...
	@tools/generate-zonemaster-profile.pl --version="$(ZONEMASTER_ENGINE_VERSION)" > rst.json
	@echo wrote rst.json

includes:
	@echo Downloading Zonemaster source code...
	@tools/install-zonemaster "$(ZONEMASTER_VERSION)"

	@echo Generating Zonemaster cases...
	@rm -rf tmp
	@mkdir tmp
	@tools/generate-zonemaster-cases.pl --version="$(ZONEMASTER_VERSION)" "$(ZM_DIR)" > tmp/zonemaster-cases.yaml

	@echo Generating Zonemaster errors...
	@tools/generate-zonemaster-cases.pl --version="$(ZONEMASTER_VERSION)" --errors "$(ZM_DIR)" > tmp/zonemaster-errors.yaml

	@echo Generating RDAP cases...
	@tools/generate-rdap-cases.pl "./etc/rdap conformance tool_v5.docx" > tmp/rdapct-cases.yaml

yaml:
	@echo Compiling YAML...
	@ZM_VERSION="$(ZONEMASTER_VERSION)" gpp -x $(src).yaml.in > $(src).yaml
	@echo wrote $(src).yaml

lint:
	@echo Checking YAML...
	@perl tools/lint.pl $(src).yaml

json:
	@echo Compiling JSON...
	@perl -MYAML::XS -MJSON::XS -e 'print JSON::XS->new->utf8->canonical->pretty->encode(YAML::XS::LoadFile("./$(src).yaml"))' > $(src).json
	@echo wrote $(src).json

html:
	@echo Compiling HTML...
	@perl tools/generate-html.pl $(src).yaml > $(src).html
	@echo wrote $(src).html

pages:
	@echo Generating pages...
	@tools/build-pages

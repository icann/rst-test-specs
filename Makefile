ZONEMASTER_VERSION=2023.1.4
src = rst-test-specs

all: export PERL5LIB=./tools/perl
all: includes yaml lint json html

includes:
	@echo Downloading Zonemaster source code...
	@tools/install-zonemaster "$(ZONEMASTER_VERSION)"

	@echo Generating Zonemaster cases...
	@tools/generate-zonemaster-cases.pl --version="$(ZONEMASTER_VERSION)" zonemaster/zonemaster-"$(ZONEMASTER_VERSION)" > inc/zonemaster-cases.yaml

	@echo Generating Zonemaster errors...
	@tools/generate-zonemaster-cases.pl --version="$(ZONEMASTER_VERSION)" --errors zonemaster/zonemaster-"$(ZONEMASTER_VERSION)" > inc/zonemaster-errors.yaml

	@echo Generating RDAP cases...
	@tools/generate-rdap-cases.pl "./etc/rdap conformance tool_v5.docx" > inc/rdap/cases.yaml

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

clean:
	@rm -rf zonemaster

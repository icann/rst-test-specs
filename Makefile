include .env

SRC = rst-test-specs
ZM_DIR=zonemaster/zonemaster-$(ZONEMASTER_VERSION)

yaml: export ZM_VERSION=$(ZONEMASTER_VERSION)

all: zonemaster-profile rdapct-config includes yaml lint json html

zonemaster-profile:
	@echo Generating Zonemaster profile...
	@tools/generate-zonemaster-profile.pl "--version=$(ZONEMASTER_ENGINE_VERSION)" > rst.json
	@echo wrote rst.json

rdapct-config:
	@echo Generating RDAP Conformance Tool configuration...
	@tools/generate-rdapct-config.pl > rdapct_config.json
	@echo wrote rdapct_config.json

includes:
	@rm -rf tmp
	@mkdir tmp

	@echo Generating version number and last-updated...
	@tools/generate-version.sh > tmp/version.txt
	@tools/generate-last-updated.sh > tmp/last-updated.txt

	@echo Downloading Zonemaster source code...
	@tools/install-zonemaster "$(ZONEMASTER_VERSION)"

	@echo Generating Zonemaster cases...
	@tools/generate-zonemaster-cases.pl "--version=$(ZONEMASTER_VERSION)" "$(ZM_DIR)" > tmp/zonemaster-cases.yaml

	@echo Generating Zonemaster errors...
	@tools/generate-zonemaster-cases.pl "--version=$(ZONEMASTER_VERSION)" --errors "$(ZM_DIR)" > tmp/zonemaster-errors.yaml

	@echo Generating data providers...
	@find tools -maxdepth 1 -type f -iname '*.pl' -print
	@tools/generate-data-providers.pl ./data > tmp/data-providers.yaml

yaml:
	@echo Compiling YAML...
	@gpp -DZONEMASTER_VERSION=$(ZONEMASTER_VERSION) -DZONEMASTER_ENGINE_VERSION=$(ZONEMASTER_ENGINE_VERSION) -x $(SRC).yaml.in > $(SRC).yaml
	@echo wrote $(SRC).yaml

lint:
	@echo Checking YAML...
	@perl tools/lint.pl $(SRC).yaml

json:
	@echo Compiling JSON...
	@perl -MYAML::XS -MJSON::XS -e 'print JSON::XS->new->utf8->canonical->pretty->encode(YAML::XS::LoadFile("./$(SRC).yaml"))' > $(SRC).json
	@echo wrote $(SRC).json

html:
	@echo Compiling HTML...
	@perl tools/generate-html.pl $(SRC).yaml > $(SRC).html
	@echo wrote $(SRC).html

pages:
	@echo Generating pages...
	@tools/build-pages

clean:
	@echo Cleaning up...
	@rm -rf tmp zonemaster _site tmp rst.json rst-test-specs.html rst-test-specs.json rst-test-specs.yaml

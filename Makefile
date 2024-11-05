eol=
BR ?= build-root

CLIGEN_VERSION ?= 1.0.0
CLIGEN_REV ?= 1
CLIGEN_PKGNAME = cligen_$(CLIGEN_VERSION)-$(CLIGEN_REV)_all.deb

CLIGEN_SRC_TGZ = $(BR)/cligen_$(CLIGEN_VERSION).orig.tar.gz
CLIGEN_RELEASE_BASEURL = https://github.com/GabrielGanne/cligen/archive/refs/tags/


.PHONY: install-dep
install-dep:
	apt update
	apt install -y \
		build-essential \
		curl \
		debhelper \
		dh-python \
		python3 \
		quilt \
		$(eol)

$(BR):
	@mkdir -p $(BR)

$(CLIGEN_SRC_TGZ): | $(BR)
	curl --location \
		--output $(CLIGEN_SRC_TGZ) \
		$(CLIGEN_RELEASE_BASEURL)/$(CLIGEN_VERSION).tar.gz

.PHONY: fetch-src
fetch-src: $(CLIGEN_SRC_TGZ)

$(BR)/package: $(CLIGEN_SRC_TGZ)
	@mkdir -p $@
	@tar --extract --directory=$@ --strip-components=1 --file=$(CLIGEN_SRC_TGZ)

$(BR)/package/debian: $(BR)/package package/debian
	@cp -ruf package/debian $@

# XXX generate a dummy changelog (to be improved)
# non-native package version MUST contain a revision
# postfix the version with a revision number articifialy to accommodate
$(BR)/package/debian/changelog: $(BR)/package/debian
	@echo "cligen ($(CLIGEN_VERSION)-$(CLIGEN_REV)) unstable; urgency=medium" > $@
	@echo "" >> $@
	@echo "  * Version $(CLIGEN_VERSION)" >> $@
	@echo "" >> $@
	@echo " -- Gabriel Ganne <gabriel.ganne@gmail.com>  $(shell date -R)" >> $@

$(BR)/$(CLIGEN_PKGNAME): $(CLIGEN_SRC_TGZ) $(BR)/package/debian $(BR)/package/debian/changelog
	@cd $(BR)/package && \
		dpkg-buildpackage --build=source,any,all --unsigned-changes --unsigned-source

.PHONY: pkg-deb
pkg-deb: $(BR)/$(CLIGEN_PKGNAME) | $(BR)/package

.PHONY: clean
clean:
	@rm -rvf $(BR)

.PHONY: lint
lint: $(BR)/$(CLIGEN_PKGNAME)
	lintian --fail-on error --no-tag-display-limit $^

.PHONY: help
help:
	@echo "# dev help target"
	@echo "install-dep          - install software dependencies"
	@echo "clean                - wipe clean all build artefacts"
	@echo "# cligen release targets"
	@echo "fetch-src            - fetch cligen source archive"
	@echo "pkg-deb              - create debian package"
	@echo "# Current Argument Values:"
	@echo "BR                   = $(BR)"
	@echo "CLIGEN_VERSION       = $(CLIGEN_VERSION)"

.DEFAULT_GOAL := help

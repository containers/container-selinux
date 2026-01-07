TARGETS ?= container
MODULES ?= ${TARGETS:=.pp.bz2}
# DATADIR seems to be the more commonly used variable
# Point SHAREDIR to DATADIR by default to not break existing users
DATADIR ?= /usr/share
SHAREDIR ?= ${DATADIR}
SYSCONFDIR ?= /etc

all: ${TARGETS:=.pp.bz2}

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -f -9 $^

%.pp: %.te
	make -f ${SHAREDIR}/selinux/devel/Makefile $@

clean:
	rm -f *~  *.tc *.pp *.pp.bz2
	rm -rf tmp *.tar.gz

man: install-policy
	sepolicy manpage --path . --domain ${TARGETS}_t

install-policy: all
	semodule -i ${TARGETS}.pp.bz2

install: man
	install -D -pm 644 ${TARGETS}.pp.bz2 ${DESTDIR}${SHAREDIR}/selinux/packages/container.pp.bz2
	install -D -pm 644 container.if ${DESTDIR}${SHAREDIR}/selinux/devel/include/services/container.if
	install -D -pm 644 container_selinux.8 ${DESTDIR}${SHAREDIR}/man/man8/container_selinux.8
	install -D -pm 644 container_contexts ${DESTDIR}${SHAREDIR}/containers/selinux/contexts

install.selinux-user:
	install -D -pm 644 container_u ${DESTDIR}${SYSCONFDIR}/selinux/targeted/contexts/users/container_u

install.udica-templates:
	install -dp $(DESTDIR)$(SHAREDIR)/udica/templates
	install -pm 644 udica-templates/*.cil $(DESTDIR)$(SHAREDIR)/udica/templates

.PHONY: validate-xml
validate-xml:
	@echo "Validating XML in policy files..."
	@hash xmllint 2>/dev/null || { echo "Error: xmllint not found. Please install libxml2." >&2; exit 1; }
	@test -d $(SHAREDIR)/selinux/devel/include/support || { echo "Error: selinux-policy-devel not properly installed." >&2; exit 1; }
	@tmpdir=$$(mktemp -d) && \
	echo "Generating XML from policy files..." && \
	python3 $(SHAREDIR)/selinux/devel/include/support/segenxml.py -w -m ./$(TARGETS) > "$$tmpdir/$(TARGETS).xml" || { echo "Error: Failed to generate XML." >&2; rm -rf "$$tmpdir"; exit 1; } && \
	echo "Validating generated XML..." && \
	xmllint --noout "$$tmpdir/$(TARGETS).xml" || { echo "Error: XML validation failed." >&2; rm -rf "$$tmpdir"; exit 1; } && \
	echo "XML validation successful." && \
	rm -rf "$$tmpdir"

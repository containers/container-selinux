TARGETS ?= container
MODULES ?= ${TARGETS:=.pp.bz2}
# DATADIR seems to be the more commonly used variable
# Point SHAREDIR to DATADIR by default to not break existing users
DATADIR ?= /usr/share
SHAREDIR ?= ${DATADIR}

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
	install -D -m 644 ${TARGETS}.pp.bz2 ${DESTDIR}${SHAREDIR}/selinux/packages/container.pp.bz2
	install -D -m 644 container.if ${DESTDIR}${SHAREDIR}/selinux/devel/include/services/container.if
	install -D -m 644 container_selinux.8 ${DESTDIR}${SHAREDIR}/man/man8/container_selinux.8
	install -D -m 644 container_contexts ${DESTDIR}${SHAREDIR}/containers/continer_contexts

install.udica-templates:
	install -D -m 644 udica-templates/*.cil $(DESTDIR)$(SHAREDIR)/udica/templates

TARGETS?=docker
MODULES?=${TARGETS:=.pp.bz2}
SHAREDIR?=/usr/share
#INSTALL=?=install

all: ${TARGETS:=.pp.bz2}

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -9 $^

%.pp: %.te
	make -f ${SHAREDIR}/selinux/devel/Makefile $@

clean:
	rm -f *~  *.tc *.pp *.pp.bz2
	rm -rf tmp *.tar.gz

#install:
#	${INSTALL} -m 0644 ${TARGETS} \
#		${DESTDIR}${SHAREDIR}/targeted/modules


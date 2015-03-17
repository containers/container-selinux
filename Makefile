# Installation directories.
PREFIX ?= $(DESTDIR)/usr

docker.pp : docker.te docker.if docker.fc
	make -f /usr/share/selinux/devel/Makefile $@

all: docker.pp

test: all
	semodule -i docker.pp

install: all 
	-mkdir -p $(PREFIX)/share/selinux/packages
	install docker.pp $(PREFIX)/share/selinux/packages

clean:
	rm -rf docker.pp *~ tmp

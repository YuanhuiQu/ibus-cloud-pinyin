PREFIX ?= /usr

VALAC= valac
CC= gcc

CFLAGS = `cat $(CFLAGFILE)` -pthread
VALAFLAGS= `cat $(VALACFLAGFILE)` --pkg ibus-1.0 --pkg posix --thread --enable-checking --vapidir=.

VALASRCS= main.vala dbus-binding.vala pinyin-utils.vala frontend-utils.vala config.vala pinyin-database.vala lua-binding.vala ibus-engine.vala
CSRCS= main.c dbus-binding.c pinyin-utils.c frontend-utils.c config.c pinyin-database.c lua-binding.c ibus-engine.c
ICONFILES= icons/ibus-cloud-pinyin.png icons/idle-0.png icons/idle-1.png icons/idle-2.png icons/idle-3.png icons/idle-4.png icons/waiting-0.png icons/waiting-1.png icons/waiting-2.png icons/waiting-3.png icons/pinyin-disabled.png icons/pinyin-enabled.png 
EXEFILES= src/ibus-cloud-pinyin

CFLAGFILE=c-flags.txt
VALACFLAGFILE=valac-flags.txt

ECHO= echo -e
INSTALL= install -p
MKDIR= mkdir -p
INSTALL_EXEC= $(INSTALL) -s -m 0755
INSTALL_DATA= $(INSTALL) -m 0644

MSG_PREFIX=\x1b[32;01m=> \x1b[39;01m
MSG_SUFFIX=\x1b[33;00m

.PHONY: all clean install

.NOTPARALLEL: $(CSRCS)

.DELETE_ON_ERROR: main.db cloud-pinyin.xml $(CSRCS)

all: $(EXEFILES) cloud-pinyin.xml main.db

$(EXEFILES): $(CFLAGFILE) $(VALACFLAGFILE)
	@$(MAKE) -C src ibus-cloud-pinyin

$(CFLAGFILE) $(VALACFLAGFILE): find-dependencies.sh
	@$(ECHO) "$(MSG_PREFIX)Finding dependencies ...$(MSG_SUFFIX)"
	@find-dependencies.sh

install: $(EXEFILES) $(ICONFILES) main.db cloud-pinyin.xml
	@$(ECHO) "$(MSG_PREFIX)Installing (prefix=$(PREFIX)) ...$(MSG_SUFFIX)"
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/db/
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/icons/
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/engine/
	@$(MKDIR) $(PREFIX)/share/ibus/component/
	$(INSTALL_DATA) main.db $(PREFIX)/share/ibus-cloud-pinyin/db/
	$(INSTALL_DATA) $(ICONFILES) $(PREFIX)/share/ibus-cloud-pinyin/icons/
	$(INSTALL_DATA) cloud-pinyin.xml $(PREFIX)/share/ibus/component/
	$(INSTALL_EXEC) $< $(PREFIX)/share/ibus-cloud-pinyin/engine/

cloud-pinyin.xml: $(EXEFILES)
	@$(ECHO) "$(MSG_PREFIX)Creating ibus compoment xml file ...$(MSG_SUFFIX)"
	@$(EXEFILES) -x > cloud-pinyin.xml

main.db: db/main.db create-index.sql
	@$(ECHO) "$(MSG_PREFIX)Clone open-phrase database ...$(MSG_SUFFIX)"
	@cp db/main.db main.db
	@$(ECHO) "$(MSG_PREFIX)Creating index. This may takes one minute. Please be patient ...$(MSG_SUFFIX)"
	@sqlite3 main.db < create-index.sql

db/main.db: pinyin-database-1.2.99.tar.bz2
	@$(ECHO) "$(MSG_PREFIX)Extracting open-phrase database ...$(MSG_SUFFIX)"
	@tar --no-same-owner -xjmf pinyin-database-1.2.99.tar.bz2

pinyin-database-1.2.99.tar.bz2:
	@$(ECHO) "$(MSG_PREFIX)Downloading open-phrase database ...$(MSG_SUFFIX)"
	@wget -c http://ibus.googlecode.com/files/pinyin-database-1.2.99.tar.bz2

clean:
	@$(ECHO) "$(MSG_PREFIX)Cleaning ...$(MSG_SUFFIX)"
	-rm -rf ibus-cloud-pinyin *.o $(CSRCS) $(CFLAGFILE) $(VALACFLAGFILE) pinyin-database-1.2.99.tar.bz2 db/ cloud-pinyin.xml main.db
	-$(MAKE) -C src clean

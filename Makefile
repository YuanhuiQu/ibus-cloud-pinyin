PREFIX ?= /usr

SRCS=src/main.vala src/dbus-binding.vala src/pinyin-utils.vala src/frontend-utils.vala src/config.vala src/database.vala src/lua-binding.vala src/ibus-engine.vala
ICONFILES=icons/ibus-cloud-pinyin.png icons/idle-0.png icons/idle-1.png icons/idle-2.png icons/idle-3.png icons/idle-4.png icons/waiting-0.png icons/waiting-1.png icons/waiting-2.png icons/waiting-3.png icons/pinyin-disabled.png icons/pinyin-enabled.png icons/traditional-disabled.png icons/traditional-enabled.png icons/offline.png
LUAFILES=lua/config.lua lua/engine_sogou.lua lua/engine_qq.lua
EXEFILES=src/ibus-engine-cloud-pinyin

CFLAGFILE=c-flags.txt
VALACFLAGFILE=valac-flags.txt

ECHO=echo -e
INSTALL=install -p
MKDIR=mkdir -p
INSTALL_EXEC=$(INSTALL) -s -m 0755
INSTALL_DATA=$(INSTALL) -m 0644

MSG_PREFIX=\x1b[32;01m=> \x1b[39;01m
MSG_SUFFIX=\x1b[33;00m

.PHONY: all clean install

.DELETE_ON_ERROR: main.db cloud-pinyin.xml

all: $(EXEFILES) cloud-pinyin.xml main.db

$(EXEFILES): $(CFLAGFILE) $(VALACFLAGFILE) $(SRCS)
	@export PREFIX
	@$(MAKE) -C src ibus-engine-cloud-pinyin

$(CFLAGFILE) $(VALACFLAGFILE): find-dependencies.sh
	@$(ECHO) "$(MSG_PREFIX)Finding dependencies ...$(MSG_SUFFIX)"
	@find-dependencies.sh

install: $(EXEFILES) $(ICONFILES) main.db cloud-pinyin.xml $(LUAFILES)
	@$(ECHO) "$(MSG_PREFIX)Installing (prefix=$(PREFIX)) ...$(MSG_SUFFIX)"
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/db/
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/icons/
	@$(MKDIR) $(PREFIX)/share/ibus-cloud-pinyin/lua/
	@$(MKDIR) $(PREFIX)/lib/ibus/
	@$(MKDIR) $(PREFIX)/share/ibus/component/
	$(INSTALL_DATA) $(LUAFILES) $(PREFIX)/share/ibus-cloud-pinyin/lua/
	$(INSTALL_DATA) main.db $(PREFIX)/share/ibus-cloud-pinyin/db/
	$(INSTALL_DATA) $(ICONFILES) $(PREFIX)/share/ibus-cloud-pinyin/icons/
	$(INSTALL_DATA) cloud-pinyin.xml $(PREFIX)/share/ibus/component/
	$(INSTALL_EXEC) $< $(PREFIX)/lib/ibus/

cloud-pinyin.xml: $(EXEFILES)
	@$(ECHO) "$(MSG_PREFIX)Creating ibus compoment xml file ...$(MSG_SUFFIX)"
	@$(EXEFILES) -x > cloud-pinyin.xml

main.db: db/main.db create-index.sql
	@$(ECHO) "$(MSG_PREFIX)Clone open-phrase database ...$(MSG_SUFFIX)"
	@cp db/main.db main.db
	@$(ECHO) "$(MSG_PREFIX)Creating index. This may takes minutes. Please be patient ...$(MSG_SUFFIX)"
	@sqlite3 main.db < create-index.sql

db/main.db: pinyin-database-1.2.99.tar.xz
	@$(ECHO) "$(MSG_PREFIX)Extracting open-phrase database ...$(MSG_SUFFIX)"
	@tar --no-same-owner -xJmf pinyin-database-1.2.99.tar.xz

pinyin-database-1.2.99.tar.xz:
	@$(ECHO) "$(MSG_PREFIX)Downloading open-phrase database ...$(MSG_SUFFIX)"
	@wget -c http://ibus-cloud-pinyin.googlecode.com/files/pinyin-database-1.2.99.tar.xz

clean:
	@$(ECHO) "$(MSG_PREFIX)Cleaning ...$(MSG_SUFFIX)"
	-rm -rf ibus-cloud-pinyin *.o $(CFLAGFILE) $(VALACFLAGFILE) pinyin-database-1.2.99.tar.bz2 db/ cloud-pinyin.xml main.db
	-$(MAKE) -C src clean

VALAC= valac
CC= gcc
CFLAGS = `cat $(CFLAGFILE)` -pthread
VALAFLAGS= `cat $(VALACFLAGFILE)` --pkg ibus-1.0 --pkg posix --thread --enable-checking --vapidir=.
VALASRCS= main.vala dbus-binding.vala pinyin-utils.vala frontend-utils.vala config.vala pinyin-database.vala lua-binding.vala ibus-engine.vala
CSRCS= main.c dbus-binding.c pinyin-utils.c frontend-utils.c config.c pinyin-database.c lua-binding.c ibus-engine.c

CFLAGFILE=c-flags.txt
VALACFLAGFILE=valac-flags.txt

ECHO= echo -e

MSG_PREFIX=\x1b[32;01m=> \x1b[39;01m
MSG_SUFFIX=\x1b[33;00m

.PHONY: all clean install

.NOTPARALLEL: $(CSRCS)

all: ibus-cloud-pinyin 

ibus-cloud-pinyin: $(CFLAGFILE) $(CSRCS)
	@$(ECHO) "$(MSG_PREFIX)Building $@ ...$(MSG_SUFFIX)"
	@$(CC) $(CFLAGS) $(CSRCS) -o $@

$(CSRCS): $(VALACFLAGFILE) $(VALASRCS)
	@$(ECHO) "$(MSG_PREFIX)Generating C files ...$(MSG_SUFFIX)"
	@-rm -rf $(CSRCS)
	@$(VALAC) $(VALAFLAGS) --disable-warnings -q -C $(VALASRCS)
	@$(ECHO) "$(MSG_PREFIX)Patching main.c (workaround for valac) ...$(MSG_SUFFIX)"
	@sed -i 's/gdk_threads_init/dbus_threads_init_default();gdk_threads_init/' main.c

$(CFLAGFILE) $(VALACFLAGFILE): find-dependencies.sh
	@$(ECHO) "$(MSG_PREFIX)Finding dependencies ...$(MSG_SUFFIX)"
	@find-dependencies.sh

ibus-engine-vala: test.vala
	@valac --pkg ibus-1.0 --pkg enchant $^ -C
	@valac -g --pkg ibus-1.0 --pkg enchant $^ -o $@

install: ibus-cloud-pinyin;

clean:
	@$(ECHO) "$(MSG_PREFIX)Cleaning ...$(MSG_SUFFIX)"
	@-rm -rf ibus-cloud-pinyin *.o $(CSRCS) $(CFLAGFILE) $(VALACFLAGFILE)

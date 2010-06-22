PREFIX ?= /usr

VALAC=valac
CC=gcc

CFLAGS = `cat $(CFLAGFILE)` -pthread
VALAFLAGS= `cat $(VALACFLAGFILE)` --pkg posix --thread --enable-checking --vapidir=.
VALALITEFLAGS= `cat $(VALACLITEFLAGFILE)` --pkg posix --Xcc=-Os

VALASRCS= main.vala dbus-binding.vala pinyin-utils.vala frontend-utils.vala config.vala database.vala lua-binding.vala ibus-engine.vala
CSRCS= $(VALASRCS:.vala=.c)

CFLAGFILE=c-flags.txt
VALACFLAGFILE=valac-flags.txt
VALACLITEFLAGFILE=valac-lite-flags.txt

ECHO= echo -e

MSG_PREFIX=\x1b[32;01m:: \x1b[39;01m
MSG_SUFFIX=\x1b[33;00m

.PHONY: all clean

.NOTPARALLEL: $(CSRCS)

.DELETE_ON_ERROR: $(CSRCS)

all: ibus-engine-cloud-pinyin ibus-cloud-pinyin-request

ibus-engine-cloud-pinyin: $(CFLAGFILE) $(CSRCS)
	@$(ECHO) "$(MSG_PREFIX)Building $@ ...$(MSG_SUFFIX)"
	$(CC) $(CFLAGS) $(CSRCS) -g -o $@

ibus-cloud-pinyin-request: request-main.vala $(VALACLITEFLAGFILE)
	@$(ECHO) "$(MSG_PREFIX)Building $@ ...$(MSG_SUFFIX)"
	$(VALAC) $(VALALITEFLAGS) --disable-warnings -o $@ $<

$(CSRCS): $(VALACFLAGFILE) $(VALASRCS)
	@$(ECHO) "$(MSG_PREFIX)Generating C files ...$(MSG_SUFFIX)"
	@-rm -rf $(CSRCS)
	$(VALAC) $(VALAFLAGS) --disable-warnings  -C $(VALASRCS)
	@#$(VALAC) $(VALAFLAGS) -C $(VALASRCS)
	@$(ECHO) "$(MSG_PREFIX)Patching C files (workaround for valac) ...$(MSG_SUFFIX)"
	if ! grep -qe 'dbus_[^t]*thread' main.c; then sed -i 's/gdk_threads_init/dbus_g_thread_init();gdk_threads_init/' main.c; fi
	for i in *.c; do sed -i "s#@PREFIX@#$(PREFIX)#g" $$i; done

clean:
	@$(ECHO) "$(MSG_PREFIX)Cleaning src ...$(MSG_SUFFIX)"
	-rm -rf ibus-engine-cloud-pinyin *.o $(CSRCS)

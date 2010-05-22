/*
 * File:   config.h
 * Author: WU Jun <quark@lihdd.net>
 */

#ifndef _CONFIG_H
#define	_CONFIG_H


#ifndef PKGDATADIR
#define PKGDATADIR "/usr/share/ibus-cloud-pinyin"
#endif

#ifndef APP_ICON_PATH
#define APP_ICON PKGDATADIR "/icons/ibus-cloud-pinyin.png"
#endif

#ifndef APP_STARTUP_SCRIPT_PATH
#define APP_STARTUP_SCRIPT_PATH PKGDATADIR "/config/config.lua"
#endif

#ifndef PINYIN_DATABASE_PATH
#define PINYIN_DATABASE_PATH PKGDATADIR "/db/main.db"
#endif

#ifndef LUA_LIBNAME
#define LUA_LIBNAME "ime"
#endif

#ifndef VERSION
#define VERSION "1.0.0"
#endif



#endif	/* _CONFIG_H */


/* 
 * File:   LuaValue.h
 * Author: WU Jun <quark@lihdd.net>
 */

#ifndef _LUAVALUE_H
#define	_LUAVALUE_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <string>
#include <ostream>
#include <map>

#include "LuaState.h"

namespace lua {

    enum LuaType {
        NIL = 0,
        BOOLEAN,
        LIGHT_USER_DATA,
        NUMBER,
        STRING,
        TABLE,
        FUNCTION,
        USER_DATA,
        THREAD
    };

    class LuaValue {
    public:
        LuaValue();
        LuaValue(const std::string value);
        LuaValue(const lua_Number value);
        LuaValue(const bool value);

        LuaValue(const int value);
        LuaValue(const size_t value);
        LuaValue(const char * value);

        LuaValue(const LuaValue & that);

        const LuaType get_type() const;
        const bool get_boolean() const;
        const std::string get_string() const;
        const lua_Number get_number() const;

        const std::map<LuaIndex, lua::LuaValue> get_table() const;

        void set_nil();
        void set_boolean(const bool value);
        void set_string(const std::string value);
        void set_number(const lua_Number value);

        const bool operator ==(const LuaValue & that) const;
        LuaValue & operator =(const LuaValue & that);

    private:
        LuaType type;
        std::string string_value;
        bool boolean_value;
        lua_Number number_value;

        friend class LuaState;
        LuaValue(lua_State * L, int index = -1);
        void read_from_stack(lua_State * L, int index = -1);
    };

}

#endif	/* _LUAVALUE_H */


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

    /**
     * lua type, defined same as LUA_T*
     */
    enum LuaType {
        NIL = LUA_TNIL,
        BOOLEAN = LUA_TBOOLEAN,
        LIGHT_USER_DATA = LUA_TLIGHTUSERDATA,
        NUMBER = LUA_TNUMBER,
        STRING = LUA_TSTRING,
        TABLE = LUA_TTABLE,
        FUNCTION = LUA_TFUNCTION,
        USER_DATA = LUA_TUSERDATA,
        THREAD = LUA_TTHREAD,
        NONE = LUA_TNONE,
    };
    
    typedef std::map<LuaIndex, LuaValue> LuaTable;

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

        const LuaTable get_table() const;

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
        LuaTable table_content;

        friend class LuaState;
        LuaValue(lua_State * L, int index = -1, int expand_level = 2);

        /**
         * read value directly from lua stack, private
         * should be called from friend LuaState
         *
         * @param expand_level how many level table should be expanded,
         *                     1 if only to expand this level (if is table)
         */
        void read_from_stack(lua_State * L,
                int index = -1, int expand_level = 2);
    };

}

#endif	/* _LUAVALUE_H */


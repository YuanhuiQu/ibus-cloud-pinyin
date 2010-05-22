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

#include "LuaException.h"
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

    class LuaState;

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
        LuaValue(LuaState & state);

        virtual ~LuaValue();
        const LuaType get_type() const;

        // operator const std::string() const;
        // operator const lua_Number() const;
        // operator const bool() const;

        // operator const int() const;
        // operator const size_t() const;
        // operator const char * () const;
        const bool get_boolean() const;
        const std::string get_string() const;
        const lua_Number get_number() const;

        void clear();
        
        LuaValue & operator =(const bool value);
        LuaValue & operator =(const lua_Number value);
        LuaValue & operator =(const std::string value);

        LuaValue & operator =(const int value);
        LuaValue & operator =(const size_t value);
        LuaValue & operator =(const char * value);

        const bool operator ==(const LuaValue & that) const;

    private:
        friend class LuaState;

        LuaType type;

        std::string string_value;
        bool boolean_value;
        lua_Number number_value;

        LuaValue(lua_State * L, int index = -1);
        void read_value(lua_State * L, int index = -1);
    };

}

#endif	/* _LUAVALUE_H */


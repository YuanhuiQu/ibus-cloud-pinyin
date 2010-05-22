/* 
 * File:   LuaState.h
 * Author: WU Jun <quark@lihdd.net>
 */

#ifndef _LUASTATE_H
#define	_LUASTATE_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <boost/variant.hpp>
#include <boost/thread/recursive_mutex.hpp>

#include <vector>
#include <string>

#include "LuaException.h"
#include "LuaValue.h"

namespace lua {

    using boost::recursive_mutex;
    using boost::variant;
    using std::vector;
    // using lua::LuaValue;

    typedef variant<lua_Number, std::string> LuaIndex;

    //typedef vector<LuaValue> LuaFunction(vector<LuaValue> parameters);

    class LuaValue;

    class LuaState : boost::noncopyable {
    public:
        LuaState();
        ~LuaState();

        const LuaValue get_field(const LuaValue& default_value);

        bool set_field(LuaIndex index, LuaValue value);

        operator const LuaValue();

        // for converience:
        operator const lua_Number();
        operator const std::string();

        void operator ()(const std::string script);

        LuaState & operator [](LuaIndex index);

        void do_string(const std::string script);

        int get_stack_size();

    private:
        friend class LuaValue;
        LuaState & operator <<(const LuaValue& value);
        LuaState & operator >>(LuaValue& value);

        bool try_reach(const bool clean_indexes = true);
        void unreach();

        size_t reach_pushed_count;
        vector<LuaIndex> indexes;
        lua_State * L;
        recursive_mutex stackMutex;
    };

}

#endif	/* _LUASTATE_H */


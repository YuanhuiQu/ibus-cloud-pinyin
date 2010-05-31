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
#include <boost/thread/mutex.hpp>

#include <vector>
#include <map>
#include <string>

#include "LuaException.h"

namespace lua {
    typedef boost::variant<lua_Number, std::string> LuaIndex;
    class LuaValue;
    class LuaState;
}

#include "LuaValue.h"

namespace lua {
    typedef std::vector<LuaValue> LuaFunction(std::vector<LuaValue>);

    class LuaState : boost::noncopyable {
    public:
        LuaState();
        ~LuaState();

        /**
         * get field, same as (LuaValue) casting, but allows a default value
         * thread safe
         */
        const LuaValue get_field(const LuaValue& default_value);

        /**
         * set field under the table by indexes pushed by []
         * thread safe
         * @return true if successful
         */
        bool set_field(LuaIndex index, LuaValue value);

        /**
         * cast into LuaValue
         * thread safe
         * get value from indexes pushed by []
         */
        operator const LuaValue();

        /**
         * alias for do_string
         */
        void operator ()(const std::string script);

        /**
         * push an index
         * thread safe
         * @example lua_state["_G"]["_VERSION"].get_field("unknown version")
         */
        LuaState & operator [](LuaIndex index);

        /**
         * do lua script, in protected mode
         * thread safe
         * blocking if previous operation not finished in one thread
         * @throw LuaExpection
         */
        void do_string(const std::string script);

        /**
         * register a LuaFunction to this class
         * thread safe
         * @return true if successful
         */
        bool register_function(const std::string name, LuaFunction * function);

        void self_check();

    private:
        friend class LuaValue;

        LuaState & operator <<(const LuaValue& value);
        LuaState & operator >>(LuaValue& value);

        /**
         * try to reach indexes, resume all if fails
         * @return true if successful
         */
        bool try_reach(const bool clean_indexes = true);

        /**
         * pop elements left in stack, call this if try_reach successed
         */
        void unreach();

        /**
         * store the count of elements try_reach pushed in the stack
         */
        size_t reach_pushed_count;

        /**
         * a map storing lua_State * => LuaState * relation
         * used by wrapped_cfunction to query LuaState * from lua_State *
         */
        static std::map<lua_State *, LuaState *> wrapped_states;

        /**
         * a proxy function registered in lua
         * it calls c++ functions registered in this class
         */
        static int wrapped_cfunction(lua_State * L);

        /**
         * indexes user pushed in this class, used in try_reach
         */
        std::vector<LuaIndex> indexes;

        /**
         * map storing c++ functions registered to this class,
         * they are exported to lua
         */
        std::map<std::string, LuaFunction *> registered_functions;

        /**
         * raw lua state
         * use 'L' as var name here for most examples of lua lib do the same
         */
        lua_State * L;

        /**
         * mutex when operating on lua stack
         */
        boost::recursive_mutex stack_mutex;

        /**
         * mutex protect indexes
         */
        boost::mutex indexes_mutex;

        /**
         * mutex for do_string
         */
        boost::mutex execute_mutex;

        /**
         * mutex for register_function, protect registered_functions
         */
        boost::mutex registered_functions_mutex;

        /**
         * mutex to protect wrapped_states
         */
        static boost::mutex wrapped_states_mutex;
    };

}

#endif	/* _LUASTATE_H */


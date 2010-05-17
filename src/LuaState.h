/* 
 * File:   LuaState.h
 * Author: quark
 *
 * Created on May 15, 2010, 3:52 AM
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
#include <exception>
#include <vector>
#include <string>

namespace lua {

    using boost::recursive_mutex;
    using boost::variant;
    using std::vector;
    using std::string;

    typedef variant<lua_Number, string> LuaIndex;

    class LuaException : public std::exception {
    private:
        string message;
    public:
        LuaException(const char * message = "") throw ();
        ~LuaException() throw ();
        virtual const char* what() const throw ();
    };

    class LuaState : boost::noncopyable {
    public:
        LuaState();
        ~LuaState();

        const lua_Number get_field(const lua_Number default_value = 0);
        const string get_field(const string default_value = "");

        bool set_field(LuaIndex index, LuaIndex value);

        operator const lua_Number();
        operator const string();
        void operator ()(const string script);

        LuaState & operator [](LuaIndex index);

        void do_string(const string script);

        int get_stack_size();
    private:
        //class stack_push_visitor;
        bool try_reach(const bool clean_indexes = true);
        void unreach();

        size_t reach_pushed_count;
        vector<LuaIndex> indexes;
        lua_State * L;
        recursive_mutex stackMutex;
    };

}

#endif	/* _LUASTATE_H */


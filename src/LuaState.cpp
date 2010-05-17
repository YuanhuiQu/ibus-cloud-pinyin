/* 
 * File:   LuaState.cpp
 * Author: quark
 * 
 * Created on May 15, 2010, 3:52 AM
 */

#include <boost/foreach.hpp>
#include <boost/format.hpp>
#include "LuaState.h"
#include <cstdio>

#define foreach BOOST_FOREACH

namespace lua {

    // LuaException

    LuaException::LuaException(const char* message) throw () {
        this->message = message;
    }

    LuaException::~LuaException() throw () {

    }

    const char * LuaException::what() const throw () {
        return message.c_str();
    }

    // stack_push_visitor (used by LuaState, not public)

    class stack_push_visitor : public boost::static_visitor<> {
    public:
        static lua_State * lua_state;

        void operator()(lua_Number & index) const {
            lua_pushnumber(lua_state, index);
        }

        void operator()(string & index) const {
            lua_pushstring(lua_state, index.c_str());
        }
    };

    lua_State * stack_push_visitor::lua_state;

    // LuaState

    LuaState::LuaState() {
        L = luaL_newstate();
        luaL_openlibs(L);
        reach_pushed_count = 0;
    }

    LuaState::~LuaState() {
        lua_close(L);
        L = NULL;
    }

    const lua_Number LuaState::get_field(const lua_Number default_value) {
        lua_Number r = default_value;
        recursive_mutex::scoped_lock lua_stack_mutex;
        if (try_reach()) {
            if (lua_isnumber(L, -1)) {
                r = lua_tonumber(L, -1);
            }
            unreach();
        }
        return r;
    }

    const string LuaState::get_field(const string default_value) {
        string r = default_value;
        recursive_mutex::scoped_lock lua_stack_mutex;
        if (try_reach()) {
            if (lua_isstring(L, -1)) {
                r = lua_tostring(L, -1);
            }
            unreach();
        }
        return r;
    }

    LuaState::operator const lua_Number() {
        return get_field(0);
    }

    LuaState::operator const string() {
        return get_field("");
    }

    bool LuaState::set_field(LuaIndex index, LuaIndex value) {
        bool successful = false;
        recursive_mutex::scoped_lock lua_stack_mutex;
        if (try_reach()) {
            lua_checkstack(L, 2);
            if (lua_istable(L, -1)) {
                stack_push_visitor::lua_state = this->L;
                boost::apply_visitor(stack_push_visitor(), index);
                boost::apply_visitor(stack_push_visitor(), value);
                lua_settable(L, -3); // push 2, pop 2
                successful = true;
            }
            unreach();
        }
        return successful;
    }

    LuaState& LuaState::operator [](LuaIndex index) {
        indexes.push_back(index);
        return *this;
    }

    void LuaState::do_string(const string script) {
        recursive_mutex::scoped_lock lua_stack_mutex;
        if (luaL_loadstring(L, script.c_str()) || lua_pcall(L, 0, 0, 0)) {
            string message = lua_tostring(L, -1);
            lua_pop(L, 1); // pop message
            throw LuaException(message.c_str());
        }
    }

    void LuaState::operator ()(const string script) {
        do_string(script);
    }

    bool LuaState::try_reach(const bool cleanIndexes) {
        lua_checkstack(L, 1 + indexes.size());

        bool successful = true;
        int previous_top = lua_gettop(L);

        // no lock here because reach() is called
        // by other methods which already locks
        // lua_stack_mutex. However, it is ok to
        // enable this lock due to it is a recursive
        // lock.
        // recursive_mutex::scoped_lock lua_stack_mutex;

        stack_push_visitor::lua_state = this->L;
        lua_getglobal(L, "_G"); // push 1
        reach_pushed_count++;

        foreach(LuaIndex index, indexes) {
            if (!lua_istable(L, -1)) {
                reach_pushed_count -=
                        (typeof (reach_pushed_count))
                        lua_gettop(L) - previous_top;
                lua_settop(L, previous_top);
                successful = false;
                break;
            }
            boost::apply_visitor(stack_push_visitor(), index);
            reach_pushed_count++;
            lua_gettable(L, -2); // pop 1, push 1
        }

        if (cleanIndexes) indexes.clear();
        return successful;
    }

    void LuaState::unreach() {
        // no lock here same reason with reach()
        lua_pop(L, reach_pushed_count);
        reach_pushed_count = 0;
    }

    int LuaState::get_stack_size() {
        return lua_gettop(L);
    }
}
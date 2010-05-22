/* 
 * File:   LuaState.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include <boost/foreach.hpp>
#include <boost/format.hpp>
#include "LuaState.h"
#include <cstdio>

#define foreach BOOST_FOREACH

// stack_push_visitor (used by LuaState, not public)

class stack_push_visitor : public boost::static_visitor<> {
public:
    static lua_State * lua_state;

    void operator()(lua_Number & index) const {
        lua_pushnumber(lua_state, index);
    }

    void operator()(std::string & index) const {
        lua_pushstring(lua_state, index.c_str());
    }
};

lua_State * stack_push_visitor::lua_state;

// LuaState

lua::LuaState::LuaState() {
    L = luaL_newstate();
    luaL_openlibs(L);
    reach_pushed_count = 0;
}

lua::LuaState::~LuaState() {
    lua_close(L);
    L = NULL;
}

const lua::LuaValue lua::LuaState::get_field(const LuaValue& default_value) {
    LuaValue r = operator const LuaValue();
    if (r.get_type() == NIL) {
        return default_value;
    } else {
        return r;
    }
}

lua::LuaState::operator const LuaValue() {
    lua::LuaValue r;
    recursive_mutex::scoped_lock lua_stack_mutex;
    if (try_reach()) {
        r.read_value(L, -1);
        unreach();
    }
    return r;
}

lua::LuaState::operator const lua_Number() {
    return operator const LuaValue().get_number();
}

lua::LuaState::operator const std::string() {
    return operator const LuaValue().get_string();
}

bool lua::LuaState::set_field(LuaIndex index, LuaValue value) {
    bool successful = false;
    recursive_mutex::scoped_lock lua_stack_mutex;
    if (try_reach()) {
        lua_checkstack(L, 2);
        if (lua_istable(L, -1)) {
            stack_push_visitor::lua_state = this->L;
            boost::apply_visitor(stack_push_visitor(), index);
            *this << value;
            lua_settable(L, -3); // push 2, pop 2
            successful = true;
        }
        unreach();
    }
    return successful;
}

lua::LuaState& lua::LuaState::operator [](LuaIndex index) {
    indexes.push_back(index);
    return *this;
}

void lua::LuaState::do_string(const std::string script) {
    recursive_mutex::scoped_lock lua_stack_mutex;
    if (luaL_loadstring(L, script.c_str()) || lua_pcall(L, 0, 0, 0)) {
        std::string message = lua_tostring(L, -1);
        lua_pop(L, 1); // pop message
        throw LuaException(message.c_str());
    }
}

void lua::LuaState::operator ()(const std::string script) {
    do_string(script);
}

bool lua::LuaState::try_reach(const bool cleanIndexes) {
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

void lua::LuaState::unreach() {
    // no lock here same reason with reach()
    lua_pop(L, reach_pushed_count);
    reach_pushed_count = 0;
}

int lua::LuaState::get_stack_size() {
    return lua_gettop(L);
}

lua::LuaState & lua::LuaState::operator <<(const LuaValue& value) {
    switch (value.get_type()) {
        case NIL:
            lua_pushnil(L);
            break;
        case BOOLEAN:
            lua_pushboolean(L, value.boolean_value ? 1 : 0);
            break;
        case NUMBER:
            lua_pushnumber(L, value.number_value);
            break;
        case STRING:
            lua_pushstring(L, value.string_value.c_str());
            break;
        case TABLE:
            // TODO: push a table
            break;
    }
    return *this;
}

lua::LuaState & lua::LuaState::operator >>(lua::LuaValue& value) {
    value.read_value(L, -1);
    lua_pop(L, 1);
    return *this;
}
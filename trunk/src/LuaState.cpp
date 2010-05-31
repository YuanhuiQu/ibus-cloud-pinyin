/* 
 * File:   LuaState.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include <boost/foreach.hpp>
#include <boost/format.hpp>
#include "LuaState.h"
#include "LuaException.h"
#include <cstdio>

#define foreach BOOST_FOREACH

// stack_push_visitor (used by LuaState, private)

class stack_push_visitor : public boost::static_visitor<> {
public:
    static lua_State * current_lua_state;

    void operator()(lua_Number & index) const {
        lua_pushnumber(current_lua_state, index);
    }

    void operator()(std::string & index) const {
        lua_pushstring(current_lua_state, index.c_str());
    }
};

lua_State * stack_push_visitor::current_lua_state;

// LuaState

static const char WRAPPED_LUA_CFUNCTION_NAME[] = "_wrapped_cfunc";
std::map<lua_State *, lua::LuaState *> lua::LuaState::wrapped_states;
boost::mutex lua::LuaState::wrapped_states_mutex;

lua::LuaState::LuaState() {
    L = luaL_newstate();
    luaL_openlibs(L);
    lua_register(L, WRAPPED_LUA_CFUNCTION_NAME, lua::LuaState::wrapped_cfunction);
    {
        boost::mutex::scoped_lock scoped_lock(wrapped_states_mutex);
        wrapped_states[L] = this;
    }
    reach_pushed_count = 0;
}

lua::LuaState::~LuaState() {
    {
        boost::mutex::scoped_lock scoped_lock(wrapped_states_mutex);
        wrapped_states.erase(L);
    }
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
    boost::recursive_mutex::scoped_lock scoped_mutex(stack_mutex);
    if (try_reach()) {
        r.read_from_stack(L, -1);
        unreach();
    }
    return r;
}

bool lua::LuaState::set_field(LuaIndex index, LuaValue value) {
    bool successful = false;
    boost::recursive_mutex::scoped_lock scoped_mutex(stack_mutex);
    if (try_reach()) {
        lua_checkstack(L, 2);
        if (lua_istable(L, -1)) {
            stack_push_visitor::current_lua_state = this->L;
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
    boost::mutex::scoped_lock scoped_mutex(indexes_mutex);
    indexes.push_back(index);
    return *this;
}

void lua::LuaState::do_string(const std::string script) {
    boost::mutex::scoped_lock scoped_execute_mutex(execute_mutex);
    boost::recursive_mutex::scoped_lock scoped_stack_mutex(stack_mutex);
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
    // stack_mutex. However, it is ok to
    // add lock here due to it is a recursive
    // mutex.

    stack_push_visitor::current_lua_state = this->L;
    lua_getglobal(L, "_G"); // push 1
    reach_pushed_count++;

    for (std::vector<LuaIndex>::iterator it = indexes.begin();
            it != indexes.end(); ++it) {
        LuaIndex & index = *it;
        if (!lua_istable(L, -1)) {
            // resume
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

void lua::LuaState::self_check() {
    if (lua_gettop(L) != 0) {
        LUA_FATAL_ERROR("LuaState: self check fails.")
    }
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
            // TODO: impl. push a table
            break;
    }
    return *this;
}

lua::LuaState & lua::LuaState::operator >>(lua::LuaValue& value) {
    value.read_from_stack(L, -1);
    lua_pop(L, 1);
    return *this;
}

bool lua::LuaState::register_function(const std::string name, LuaFunction * function) {
    try {
        boost::mutex::scoped_lock scoped_lock(registered_functions_mutex);
        do_string((
                boost::format("%1% = function(...) "
                "return %2%(\"%1%\", ...) end"
                ) % name % WRAPPED_LUA_CFUNCTION_NAME).str());
        registered_functions[name] = function;
    } catch (LuaException) {
        return false;
    }
    return true;
}

int lua::LuaState::wrapped_cfunction(lua_State * L) {
    std::vector <LuaValue> parameters;
    LuaState * state;
    LuaFunction * function;

    // this function is called most likely from do_string
    // thus, stack_mutex is already locked

    int parameter_count = lua_gettop(L);
    for (int i = 2; i <= parameter_count; i++) {
        parameters.push_back(LuaValue(L, i));
    }

    // find out which LuaFunction in which LuaState should be called
    {
        boost::mutex::scoped_lock wrapped_states_lock(wrapped_states_mutex);
        std::map<lua_State *, lua::LuaState *>::iterator lua_state_iterator
                = wrapped_states.find(L);

        if (lua_state_iterator == wrapped_states.end()) {
            // invalid state, return nothing
            LUA_WARNING("LuaState: "
                    "Invalid lua state found. This shouldn't happen.\n")
            return 0;
        }
        state = lua_state_iterator->second;
    }

    std::string function_name = lua_tostring(L, 1);
    {
        boost::mutex::scoped_lock function_lock
                (state->registered_functions_mutex);

        std::map<std::string, LuaFunction *>::iterator function_iterator
                = state->registered_functions.find(function_name);

        if (function_iterator == state->registered_functions.end()) {
            // invalid function name, return nothing
            LUA_WARNING("LuaState: "
                    "Invalid function name. This shouldn't happen.\n")
            return 0;
        }
        function = function_iterator->second;
    }

    // call that function, get results
    std::vector<LuaValue> results
            = (*function)(parameters);

    // push results
    for (std::vector<LuaValue>::iterator it = results.begin();
            it != results.end();
            ++it) {
        *state << *it;
    }

    return (int) (results.size());
}
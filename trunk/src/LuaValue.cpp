/* 
 * File:   LuaValue.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include <boost/format.hpp>
#include "LuaValue.h"

lua::LuaValue::LuaValue(const lua::LuaValue & that) {
    // TODO: copy construct
    type = that.type;
    string_value = that.string_value;
    boolean_value = that.boolean_value;
    number_value = that.number_value;
}

lua::LuaValue::LuaValue(LuaState& state) {
    *this = state.operator const LuaValue();
}

lua::LuaValue::LuaValue() {
    clear();
}

lua::LuaValue::LuaValue(const std::string value) {
    operator =(value);
}

lua::LuaValue::LuaValue(const lua_Number value) {
    operator =(value);
}

lua::LuaValue::LuaValue(const bool value) {
    operator =(value);
}

lua::LuaValue::LuaValue(const int value) {
    operator =((lua_Number) value);
}

lua::LuaValue::LuaValue(const size_t value) {
    operator =((lua_Number) value);
}

lua::LuaValue::LuaValue(const char * value) {
    operator =(std::string(value));
}

lua::LuaValue::LuaValue(lua_State * L, int index) {
    read_value(L, index);
}

void lua::LuaValue::clear() {
    type = NIL;
    string_value = "";
    number_value = 0;
    boolean_value = false;
}

lua::LuaValue & lua::LuaValue::operator =(const std::string value) {
    type = STRING;
    string_value = value;
    number_value = (lua_Number) value.c_str()[0];
    boolean_value = !value.empty();
    return *this;
}

lua::LuaValue & lua::LuaValue::operator =(const lua_Number value) {
    type = NUMBER;
    string_value = (boost::format("%1%") % value).str();
    number_value = value;
    boolean_value = (value != 0);
    return *this;
}

lua::LuaValue & lua::LuaValue::operator =(const bool value) {
    type = BOOLEAN;
    string_value = value ? "true" : "false";
    number_value = value ? 1 : 0;
    boolean_value = value;
    return *this;
}

lua::LuaValue & lua::LuaValue::operator =(const int value) {
    return operator =((lua_Number) value);
}

lua::LuaValue & lua::LuaValue::operator =(const size_t value) {
    return operator =((lua_Number) value);
}

lua::LuaValue & lua::LuaValue::operator =(const char* value) {
    return operator =(std::string(value));
}

void lua::LuaValue::read_value(lua_State * L, int index) {
    switch (lua_type(L, index)) {
        case LUA_TNIL:
            clear();
            break;
        case LUA_TNONE:
            // do nothing
            break;
        case LUA_TBOOLEAN:
            operator =((bool)lua_toboolean(L, index));
            break;
        case LUA_TNUMBER:
            operator =(lua_tonumber(L, index));
            break;
        case LUA_TSTRING:
            operator =((std::string)lua_tostring(L, index));
            break;
        case LUA_TTABLE:
            // TODO: iterative get table content
            break;
        case LUA_TFUNCTION:
        case LUA_TLIGHTUSERDATA:
        case LUA_TTHREAD:
        case LUA_TUSERDATA:
        default:
            // not supported
            FATAL_ERROR("not supported lua_type");
    }
}

/*
lua::LuaValue::operator const bool() const {
    return boolean_value;
}

lua::LuaValue::operator const lua_Number() const {
    return number_value;
}

lua::LuaValue::operator const std::string() const {
    return string_value;
}

lua::LuaValue::operator const int() const {
    return (int) operator const lua_Number();
}

lua::LuaValue::operator const size_t() const {
    return (size_t) operator const lua_Number();
}


lua::LuaValue::operator const char * () const {
    return string_value.c_str();
}
*/

const bool lua::LuaValue::get_boolean() const {
    return boolean_value;
}

const lua_Number lua::LuaValue::get_number() const {
    return number_value;
}

const std::string lua::LuaValue::get_string() const {
    return string_value;
}

lua::LuaValue::~LuaValue() {
}

const lua::LuaType lua::LuaValue::get_type() const {
    return type;
}

const bool lua::LuaValue::operator ==(const lua::LuaValue& that) const {
    if (that.type != type) return false;
    switch (type) {
        case NUMBER:
            return that.number_value == number_value;
        case NIL:
            return true;
        case STRING:
            return that.string_value == string_value;
        case TABLE:
            // TODO: compare a table
            return false;
        default:
            return false;
    }
}

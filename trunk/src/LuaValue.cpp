/* 
 * File:   LuaValue.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include <boost/format.hpp>
#include "LuaValue.h"
#include "LuaException.h"

lua::LuaValue::LuaValue(const lua::LuaValue & that) {
    operator =(that);
}

lua::LuaValue::LuaValue() {
    set_nil();
}

lua::LuaValue::LuaValue(const std::string value) {
    set_string(value);
}

lua::LuaValue::LuaValue(const lua_Number value) {
    set_number(value);
}

lua::LuaValue::LuaValue(const bool value) {
    set_boolean(value);
}

lua::LuaValue::LuaValue(const int value) {
    set_number((lua_Number) value);
}

lua::LuaValue::LuaValue(const size_t value) {
    set_number((lua_Number) value);
}

lua::LuaValue::LuaValue(const char * value) {
    set_string(std::string(value));
}

void lua::LuaValue::set_nil() {
    type = NIL;
    string_value = "";
    number_value = 0;
    boolean_value = false;
}

void lua::LuaValue::set_boolean(const bool value) {
    type = BOOLEAN;
    string_value = value ? "true" : "false";
    number_value = value ? 1 : 0;
    boolean_value = value;
}

void lua::LuaValue::set_number(const lua_Number value) {
    type = NUMBER;
    string_value = (boost::format("%1%") % value).str();
    number_value = value;
    boolean_value = (value != 0);
}

void lua::LuaValue::set_string(const std::string value) {
    type = STRING;
    string_value = value;
    number_value = (lua_Number) value.c_str()[0];
    boolean_value = !value.empty();
}

void lua::LuaValue::read_from_stack(lua_State * L, int index, int expand_level) {
    switch (type = (lua::LuaType)lua_type(L, index)) {
        case LUA_TNIL:
            set_nil();
            break;
        case LUA_TNONE:
            // do nothing
            break;
        case LUA_TBOOLEAN:
            set_boolean((bool)lua_toboolean(L, index));
            break;
        case LUA_TNUMBER:
            set_number(lua_tonumber(L, index));
            break;
        case LUA_TSTRING:
            set_string((std::string)lua_tostring(L, index));
            break;
        case LUA_TTABLE:
            if (expand_level > 0) {
                // table can only be read in
                // when directly get value from lua stack
                // table is in the stack at index 'index'
                // traversal this table
                int table_index = index > 0 ? index : index - 1;
                for (lua_pushnil(L);
                        lua_next(L, table_index) != 0;
                        lua_pop(L, 1)) {
                    LuaIndex key
                            = (lua_type(L, -2) == LUA_TSTRING
                            ? LuaIndex(lua_tostring(L, -2))
                            : LuaIndex(lua_tonumber(L, -2)));
                    LuaValue value(L, -1, expand_level - 1);
                    table_content.insert(std::pair<LuaIndex, LuaValue >
                            (key, value));
                }
            }
            break;
        case LUA_TFUNCTION:
        case LUA_TLIGHTUSERDATA:
        case LUA_TTHREAD:
        case LUA_TUSERDATA:
        default:
            // not supported
            LUA_WARNING("LuaValue::read_from_stack: not supported lua_type");
            string_value = "";
            number_value = 0;
            boolean_value = false;
    }
}

lua::LuaValue::LuaValue(lua_State * L, int index, int expand_level) {
    read_from_stack(L, index, expand_level);
}

const bool lua::LuaValue::get_boolean() const {
    return boolean_value;
}

const lua_Number lua::LuaValue::get_number() const {
    return number_value;
}

const std::string lua::LuaValue::get_string() const {
    return string_value;
}

const lua::LuaTable lua::LuaValue::get_table() const {
    return table_content;
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

lua::LuaValue & lua::LuaValue::operator =(const lua::LuaValue & that) {
    type = that.type;
    string_value = that.string_value;
    boolean_value = that.boolean_value;
    number_value = that.number_value;
    table_content = that.table_content;
    return *this;
}

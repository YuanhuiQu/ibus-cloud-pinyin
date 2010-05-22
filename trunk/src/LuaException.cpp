/* 
 * File:   LuaException.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include "LuaException.h"

// LuaException

lua::LuaException::LuaException(const char* message) throw () {
    this->message = message;
}

lua::LuaException::~LuaException() throw () {

}

const char * lua::LuaException::what() const throw () {
    return message.c_str();
}

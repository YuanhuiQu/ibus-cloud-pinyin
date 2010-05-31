/* 
 * File:   LuaException.h
 * Author: quark
 *
 * Created on May 21, 2010, 9:43 PM
 */

#ifndef _LUAEXCEPTION_H
#define	_LUAEXCEPTION_H

#include <cstdlib>
#include <cstdio>
#include <string>
#include <exception>

#define LUA_FATAL_ERROR(message) \
    fprintf(stderr, "LUA FATAL: %s\n", message), \
    exit(EXIT_FAILURE);

#define LUA_WARNING(message) \
    fprintf(stderr, "LUA WARNING: %s\n", message);

namespace lua {

    class LuaException : public std::exception {
    private:
        std::string message;
    public:
        LuaException(const char * message = "") throw ();
        ~LuaException() throw ();
        virtual const char* what() const throw ();
    };

}

#endif	/* _LUAEXCEPTION_H */


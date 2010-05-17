#define BOOST_TEST_MAIN

#include <boost/test/unit_test.hpp>
#include "LuaState.h"

using namespace std;
using lua::LuaState;
using lua::LuaException;

BOOST_AUTO_TEST_CASE( lua_state_test ) {
    LuaState l;

    BOOST_CHECK_THROW(l.do_string("a(t)"), LuaException);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);

    BOOST_CHECK_EQUAL(l["a"].get_field(3), 3);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla"), "blabla");
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    
    BOOST_CHECK_NO_THROW(l.do_string("a=1"));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla"), "blabla");
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL(l["a"][123].get_field(345), 345);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    
    BOOST_CHECK_NO_THROW(l.do_string("b={1,2,3,['cde']={3,4,5}}"));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((lua_Number)l["b"][3], 3);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((lua_Number)l["b"][4], 0);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((std::string)l["b"][4], "");
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((lua_Number)l["b"]["cde"][2], 4);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((lua_Number)l["b"]["cde"]["abc"], 0);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((lua_Number)l["b"]["cde"][3], 5);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);

    BOOST_CHECK_EQUAL(l["a"].get_field(3), 1);
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla"), "blabla");
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);

    BOOST_CHECK(!l["a"]["b"][1][2].set_field("t", 1));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK(!l["a"].set_field("t", 1));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK(l.set_field("a", 123));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL(l["a"].get_field(345), 123);
    BOOST_CHECK(l["b"]["cde"].set_field(6, "hello"));
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
    BOOST_CHECK_EQUAL((std::string)l["b"]["cde"][6], "hello");
    BOOST_CHECK_EQUAL(l.get_stack_size(), 0);
}

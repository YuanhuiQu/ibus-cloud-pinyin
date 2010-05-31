#define BOOST_TEST_MAIN

#include <boost/test/unit_test.hpp>
#include <boost/foreach.hpp>
#include <iostream>
#include <vector>

#include "LuaState.h"

using namespace std;
using namespace boost;
using namespace lua;

std::vector<LuaValue> lua_function_test(std::vector<LuaValue> p) {
    BOOST_FOREACH(LuaValue value, p) {
        switch (value.get_type()) {
            case STRING:
                cout << "string: " << value.get_string() << endl;
                break;
            case NUMBER:
                cout << "number: " << value.get_number() << endl;
                break;
        }
    }
    std::vector<LuaValue> r;
    r.push_back("hello world");
    r.push_back(12345);
    r.push_back(-34.12);
    r.push_back("you can not pass!");
    return r;
}

BOOST_AUTO_TEST_CASE(lua_state_weak_test) {
    ios::sync_with_stdio(true);

    LuaState l;

    BOOST_CHECK_THROW(l.do_string("a(t)"), LuaException);

    BOOST_CHECK_NO_THROW(l("print('hello, world')"));
    BOOST_CHECK_NO_THROW(l.self_check());

    // register function _G.abc
    BOOST_CHECK(l.register_function("abc", &lua_function_test));
    BOOST_CHECK_NO_THROW(l("print(abc(1, 'abcdef', 3.22))"));

    /*
    BOOST_CHECK_EQUAL((LuaValue)l["a"].get_field(3) == 3, true);
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla").get_string() == "blabla", true);
    //BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla"), (LuaValue)"blabla");
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla") == LuaValue("blabla"), true);

    BOOST_CHECK_NO_THROW(l.do_string("a=4"));
    BOOST_CHECK_EQUAL(l["a"]["b"]["c"].get_field("blabla").get_string(), "blabla");
    BOOST_CHECK_EQUAL(l["a"][123].get_field(345).get_number(), 345);

    BOOST_CHECK_NO_THROW(l.do_string("b={1,2,3,['cde']={3,4,5}}"));
    BOOST_CHECK_NO_THROW(l.do_string("return 1, 2, 3"));
    BOOST_CHECK_EQUAL(((LuaValue)l["b"][3]).get_number(), 3);
    BOOST_CHECK_EQUAL(((LuaValue)l["b"][4]).get_number(), 0);
    BOOST_CHECK_EQUAL(((LuaValue)l["b"][4]).get_string(), "");
    BOOST_CHECK_EQUAL(((LuaValue) l["b"]["cde"][2]).get_number(), 4);
    BOOST_CHECK_EQUAL(((LuaValue) l["b"]["cde"]["abc"]).get_number(), 0);
    BOOST_CHECK_EQUAL(((LuaValue) l["b"]["cde"][3]).get_number(), 5);

    BOOST_CHECK(l["a"].get_field(3) == 4);
    BOOST_CHECK(l["a"]["b"]["c"].get_field("blabla") == "blabla");

    BOOST_CHECK(!l["a"]["b"][1][2].set_field("t", true));
    BOOST_CHECK_EQUAL(((LuaValue)l["a"]["b"][1][2]).get_boolean(), false);
    BOOST_CHECK_EQUAL(((LuaValue)l["tr"]).get_boolean(), false);

    BOOST_CHECK(l.set_field("tr", "abcde"));
    BOOST_CHECK_EQUAL((string)(l["tr"]) == std::string("abcde"), true);
    BOOST_CHECK_EQUAL( ((LuaValue)l["tr"]).get_string(), "abcde");

    BOOST_CHECK(l.set_field("tr", 123.5));
    BOOST_CHECK(LuaValue (l["tr"]) == 123.5);

    BOOST_CHECK(l.set_field("tr", true));
    BOOST_CHECK(((LuaValue)l["tr"]).get_boolean());

    BOOST_CHECK(!l["a"].set_field("t", 1));
    BOOST_CHECK(l.set_field("a", 123));
    BOOST_CHECK(l["a"].get_field(345) == 123);
    BOOST_CHECK(l["b"]["cde"].set_field(6, "hello"));

    BOOST_CHECK((std::string)l["b"]["cde"][6] == std::string("hello"));
     */
}

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
    return r;
}

BOOST_AUTO_TEST_CASE(lua_state_weak_test) {
    ios::sync_with_stdio(true);

    LuaState l;

    BOOST_CHECK_THROW(l.do_string("a(t)"), LuaException);

    BOOST_CHECK_NO_THROW(l("print('you should see number: 1.22 and string: asdf')"));
    BOOST_CHECK_NO_THROW(l.self_check());

    BOOST_CHECK(l.register_function("abc", &lua_function_test));
    BOOST_CHECK_NO_THROW(l("a, b, c, d = abc(1.22, 'asdf'); t = {a, b, c, d}"));

    BOOST_CHECK((LuaValue) (l["t"][1]) == LuaValue("hello world"));
    BOOST_CHECK((LuaValue) l["t"]["1"] == LuaValue());

    BOOST_CHECK((LuaValue) (l["t"][2]) == LuaValue(12345));
    BOOST_CHECK((LuaValue) (l["t"][3]) == LuaValue(-34.12));
    BOOST_CHECK(((LuaValue) (l["t"][4])).get_type() == NIL);

    BOOST_CHECK((LuaValue) (l["a"]) == LuaValue("hello world"));
    BOOST_CHECK((LuaValue) (l["b"]) == LuaValue(12345));
    BOOST_CHECK((LuaValue) (l["c"]) == LuaValue(-34.12));
    BOOST_CHECK(((LuaValue) (l["d"])).get_type() == NIL);

    BOOST_CHECK_NO_THROW(l.self_check());

    BOOST_CHECK(l["t"].set_field(1, "another") == true);
    BOOST_CHECK(l["t"].set_field("1", 345.1) == true);
    BOOST_CHECK((LuaValue) (l["t"][1]) == LuaValue("another"));
    BOOST_CHECK((LuaValue) l["t"]["1"] == LuaValue(345.1));
    BOOST_CHECK(l["t"]["2"].get_field("234") == LuaValue("234"));

    BOOST_CHECK(l["t"]["g"].set_field(1, "another") == false);
    l.self_check();
}

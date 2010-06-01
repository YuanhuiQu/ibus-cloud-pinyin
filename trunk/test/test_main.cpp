#define BOOST_TEST_MAIN

#include <boost/test/unit_test.hpp>
#include <boost/foreach.hpp>
#include <iostream>
#include <sstream>
#include <vector>

#include "LuaState.h"

using namespace std;
using namespace boost;
using namespace lua;

ostringstream *out;

std::vector<LuaValue> lua_function_test(std::vector<LuaValue> p) {

    BOOST_FOREACH(LuaValue value, p) {
        switch (value.get_type()) {
            case STRING:
                *out << "string: " << value.get_string() << endl;
                break;
            case NUMBER:
                *out << "number: " << value.get_number() << endl;
                break;
        }
    }
    std::vector<LuaValue> r;
    r.push_back("hello world");
    r.push_back(12345);
    r.push_back(-34.12);
    return r;
}

void print_table(LuaValue lv) {
    switch (lv.get_type()) {
        case TABLE:
        {
            LuaTable lua_table_map = lv.get_table();
            *out << "{ ";
            for (LuaTable::iterator it = lua_table_map.begin();
                    it != lua_table_map.end(); ++it) {
                *out << it->first << " = ";
                print_table(it->second);
                *out << ", ";
            }
            *out << "}";
            break;
        }
        case STRING:
            *out << '\'' << lv.get_string() << '\'';
            break;
        case NUMBER:
            *out << lv.get_number();
            break;
        case BOOLEAN:
            *out << boolalpha << lv.get_boolean();
            break;
        case NIL:
            *out << "nil";
            break;
        default:
            *out << "(unknown)";
    }
}

BOOST_AUTO_TEST_CASE(lua_state_weak_test) {
    ios::sync_with_stdio(true);

    LuaState l;

    BOOST_CHECK_THROW(l.do_string("a(t)"), LuaException);

    BOOST_CHECK_NO_THROW(l("if (1 == 0) then error('impossible') end "
            "print('you should see two warnings:')"));
    BOOST_CHECK_NO_THROW(l.self_check());

    out = new ostringstream();
    BOOST_CHECK(l.register_function("abc", &lua_function_test));
    BOOST_CHECK_NO_THROW(l("a, b, c, d = abc(1.22, 'asdf'); t = {a, b, c, d}"));
    BOOST_CHECK(out->str() == "number: 1.22\nstring: asdf\n");

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

    BOOST_CHECK_NO_THROW(l("k = { 'a', -12.34, false, { -3, "
            " 'bla', { 0.1, -9}, nil, bb = _G.print}, ['label'] = 'def' }"));

    BOOST_CHECK(l.get_table_expand_level() == 2);

    delete out;
    out = new ostringstream();
    print_table((LuaValue) l["k"]);
    BOOST_CHECK(out->str() == "{ 1 = 'a', 2 = -12.34, 3 = false, "
            "4 = { 1 = -3, 2 = 'bla', 3 = { }, bb = (unknown), }, "
            "label = 'def', }");

    delete out;
    out = new ostringstream();

    l.set_table_expand_level(4);
    print_table(LuaValue (l["k"]) );
    BOOST_CHECK(out->str() == "{ 1 = 'a', 2 = -12.34, 3 = false, "
            "4 = { 1 = -3, 2 = 'bla', 3 = { 1 = 0.1, 2 = -9, }, "
            "bb = (unknown), }, label = 'def', }");

    BOOST_CHECK_NO_THROW(l.self_check());
}

/* 
 * File:   main.cpp
 * Author: WU Jun <quark@lihdd.net>
 */

#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <iostream>
#include <ibus.h>
#include "config.h"

void process_program_options(int argc, char ** argv) {
    using namespace std;
    using namespace boost;
    namespace po = program_options;

    po::options_description desc("Options");
    desc.add_options()
            ("help", "print this help message")
            ("version", "show version information")
            ("ibus", "use this if you are ibus")
            ("xml", "dump ibus engine xml to stdout")
            ("shell", "open lua shell (debugging use)")
            ("config", po::value<string > (),
            "specify a startup config file"
            "default: " APP_STARTUP_SCRIPT_PATH);

    try {
        po::variables_map var_map;
        po::store(po::parse_command_line(argc, argv, desc), var_map);
        po::notify(var_map);

        if (var_map.count("help")) {
            cout << desc << "\n";
            exit(EXIT_SUCCESS);
        }

        if (var_map.count("version")) {
            cout << format("ibus-cloud-pinyin %1%\n"
                    "Copyright (C) 2010 WU Jun <quark@lihdd.net>\n"
                    "Compiled with ibus %2%.%3%.%4%, boost %5%\n")
                    % VERSION % IBUS_MAJOR_VERSION % IBUS_MINOR_VERSION
                    % IBUS_MICRO_VERSION % BOOST_VERSION;

            exit(EXIT_SUCCESS);
        }
    } catch (po::error e) {
        cerr << "Error parsing options: " << e.what() << endl;
        cerr << "Use --help to see a list of valid options." << endl;
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char** argv) {
    process_program_options(argc, argv);
    return (EXIT_SUCCESS);
}


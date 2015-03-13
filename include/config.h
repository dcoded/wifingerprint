#ifndef INCLUDE_CONFIG_H
#define INCLUDE_CONFIG_H

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/ini_parser.hpp>

using namespace boost::property_tree;

class config {
private:
    boost::property_tree::ptree property_tree_;
public:
    config(std::string filename = "config.ini") {
        ini_parser::read_ini(filename, property_tree_);
    }

    template<typename T = std::string>
    std::string operator[](std::string key) {
        return property_tree_.get<T>(key);
    }
};

#endif
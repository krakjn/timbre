#pragma once

#include <string>
#include <map>
#include <regex>
#include "log.h"

namespace timbre {

struct Config {
    std::string log_dir;
    std::map<std::string, std::regex> log_levels;
    Config() : log_dir(".timbre") {}
};

bool load_config(const std::string& filename, Config& config);
Config& get_config();

}
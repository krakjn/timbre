#pragma once

#include <string>
#include <map>
#include <regex>
#include <fstream>
#include "log.h"

namespace timbre {

struct LogLevelConfig {
    std::regex pattern;
    std::string file;  // Log file path relative to log_dir
};

struct Config {
    std::string log_dir;
    std::map<std::string, LogLevelConfig> log_levels;
    
    Config() : log_dir(".timbre") {}
    
    // Initialize default log levels if none are configured
    void set_defaults();
};

bool load_config(const std::string& filename, Config& config);

Config& get_config();

std::map<std::string, std::ofstream> open_log_files(const Config& config, bool append);

void close_log_files(std::map<std::string, std::ofstream>& log_files);

}
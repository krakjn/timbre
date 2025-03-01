#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <system_error>
#include <regex>
#include <algorithm>
#include <cctype>
#include "CLI/CLI11.hpp"
#include "timbre/log.h"
#include "timbre/config.h"
#include "timbre/timbre.h"

namespace timbre {

bool matches_regex(const std::string& line, const std::regex& pattern) {
    try {
        return std::regex_search(line, pattern);
    } catch (const std::regex_error& e) {
        log(LogLevel::ERROR, std::string("Regex error: ") + e.what());
        return false;
    }
}

ConfigLogLevel process_line(const std::string& line, std::map<std::string, std::ofstream>& log_files, bool quiet) {
    // Always write to stdout (tee behavior) unless quiet mode is enabled
    if (!quiet) {
        printf("%s\n", line.c_str());
        fflush(stdout);
    }

    if (line.empty()) return none;

    const auto& config = get_config();
    
    for (const auto& [level_name, level_config] : config.log_levels) {
        if (matches_regex(line, level_config.pattern)) {
            auto file_it = log_files.find(level_name);
            if (file_it != log_files.end() && file_it->second.is_open()) {
                file_it->second << line << std::endl;
                if (!file_it->second.good()) {
                    log(LogLevel::ERROR, "Failed to write to log file for level: " + level_name);
                    return none;
                }
            }
            return ConfigLogLevel(level_name);
        }
    }
    
    return none;
}

}

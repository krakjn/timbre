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
#include "timbre/version.h"

namespace timbre {

void print_version() {
    if (TIMBRE_IS_DEV) {
        printf("timbre version %d.%d.%d-dev (build %s)\n", 
            TIMBRE_VERSION_MAJOR, 
            TIMBRE_VERSION_MINOR, 
            TIMBRE_VERSION_PATCH, 
            TIMBRE_VERSION_SHA
        );
    } else {
        printf("timbre version %d.%d.%d\n", 
            TIMBRE_VERSION_MAJOR, 
            TIMBRE_VERSION_MINOR, 
            TIMBRE_VERSION_PATCH
        );
    }
}

bool match(const std::string& line, const std::regex& pattern) {
    try {
        return std::regex_search(line, pattern);
    } catch (const std::regex_error& e) {
        log(LogLevel::ERROR, std::string("Regex error: ") + e.what());
        return false;
    }
}

void process_line(
    UserConfig& config, 
    const std::string& line, 
    std::map<std::string, std::ofstream>& log_files,
    bool quiet) {

    // Always write to stdout (tee behavior) unless quiet mode is enabled
    if (!quiet) {
        std::cout << line << '\n' << std::flush;
    }

    if (line.empty()) return;
    
    // NOLINTBEGIN: unassignedVariable
    for (auto& [level_name, level_config] : config.get_log_levels()) { // NOLINT
        if (match(line, level_config.pattern)) {
            level_config.count++;  // Increment the count for matched level
            auto file_it = log_files.find(level_name);
            if (file_it != log_files.end() && file_it->second.is_open()) {
                file_it->second << line << '\n';
                if (!file_it->second.good()) {
                    log(LogLevel::ERROR, "Failed to write to log file for level: " + level_name);
                    return;
                }
            }
            return;
        }
    }
    // NOLINTEND
}

std::map<std::string, std::ofstream> open_log_files(UserConfig& config, bool append) {
    std::map<std::string, std::ofstream> log_files;
    
    std::filesystem::create_directories(config.get_log_dir());
    for (auto& [level_name, level_config] : config.get_log_levels()) {
        std::string file_path = config.get_log_dir() + "/" + level_config.path;
        auto mode = append ? std::ios::app : std::ios::trunc;
        log_files[level_name].open(file_path, std::ios::out | mode);
        if (!log_files[level_name].is_open()) {
            log(LogLevel::ERROR, "Failed to open log file: " + file_path);
        }
    }
    
    return log_files;
}

void close_log_files(std::map<std::string, std::ofstream>& log_files) {
    for (auto& file_pair : log_files) {
        if (file_pair.second.is_open()) {
            file_pair.second.close();
        }
    }
}

}

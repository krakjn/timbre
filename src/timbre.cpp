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

ConfigLogLevel process_line(const std::string& line, std::ofstream& error_file, std::ofstream& warn_file, bool quiet) {
    if (!quiet) {
        std::cout << line << std::endl;  // Print to terminal unless suppressed
    }

    try {
        const auto& config = timbre::get_config();
        
        // First try regex patterns from configuration
        if (!config.log_levels.empty()) {
            for (const auto& [level_str, pattern] : config.log_levels) {
                if (matches_regex(line, pattern)) {
                    ConfigLogLevel level{level_str};
                    
                    if (level == error) {
                        error_file << line << std::endl;
                        if (error_file.fail()) {
                            throw std::runtime_error("Failed to write to error log file");
                        }
                    } else if (level == warn) {
                        warn_file << line << std::endl;
                        if (warn_file.fail()) {
                            throw std::runtime_error("Failed to write to warning log file");
                        }
                    }
                    return level;
                }
            }
        }
        
        // Fallback to the old pattern matching if no regex patterns matched
        static const std::regex error_pattern("error|exception|fail", 
            std::regex_constants::extended | std::regex_constants::icase);
        static const std::regex warn_pattern("warn(ing)?", 
            std::regex_constants::extended | std::regex_constants::icase);
            
        if (matches_regex(line, error_pattern)) {
            error_file << line << std::endl;
            if (error_file.fail()) {
                throw std::runtime_error("Failed to write to error log file");
            }
            return error;
        } else if (matches_regex(line, warn_pattern)) {
            warn_file << line << std::endl;
            if (warn_file.fail()) {
                throw std::runtime_error("Failed to write to warning log file");
            }
            return warn;
        }
    } catch (const std::exception& e) {
        log(LogLevel::ERROR, std::string("Error processing line: ") + e.what());
    }
    
    return none;
}

}

#include <fstream>
#include <iostream>
#include <regex>
#include "timbre/config.h"
#include "toml/toml.hpp"

namespace timbre {

// Singleton instance
static Config g_config;  

Config& get_config() {
    return g_config;
}

bool load_config(const std::string& filename, Config& config) {
    try {
        auto data = toml::parse(filename);
        
        // [timbre] section
        if (data.contains("timbre") && data.at("timbre").is_table()) {
            auto& timbre_section = toml::find(data, "timbre");
            
            if (timbre_section.contains("log_dir") && timbre_section.at("log_dir").is_string()) {
                config.log_dir = toml::find<std::string>(timbre_section, "log_dir");
                log(LogLevel::INFO, "Config: log_dir = " + config.log_dir);
            }
        }
        
        // [log_level] section
        if (data.contains("log_level") && data.at("log_level").is_table()) {
            auto& log_level_section = toml::find(data, "log_level");
            
            // Clear existing log levels
            config.log_levels.clear();
            
            // Process each key-value pair in the log_level section
            for (const auto& [key, value] : log_level_section.as_table()) {
                if (value.is_string()) {
                    std::string pattern = value.as_string();
                    try {
                        // Create a regex from the pattern with extended and case-insensitive flags
                        std::regex regex_pattern(pattern, 
                            std::regex_constants::extended | 
                            std::regex_constants::icase);
                        config.log_levels[key] = regex_pattern;
                        log(LogLevel::INFO, "Config: log_level." + key + " = " + pattern);
                    } catch (const std::regex_error& e) {
                        log(LogLevel::ERROR, "Invalid regex pattern for log level '" + key + "': " + pattern);
                        log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
                    }
                }
            }
        }
        
        return true;
    } catch (const std::exception& e) {
        log(LogLevel::ERROR, "Failed to parse config file: " + std::string(e.what()));
        return false;
    }
}
} 
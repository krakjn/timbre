#include <fstream>
#include <iostream>
#include <regex>
#include <filesystem>
#include "timbre/config.h"
#include "toml/toml.hpp"
#include "timbre/log.h"

namespace timbre {

std::regex _re_compile(const std::string& pattern) {
    try {
        return std::regex(pattern, std::regex_constants::extended
            | std::regex_constants::icase 
            | std::regex_constants::optimize 
        );
    } catch (const std::regex_error& e) {
        log(LogLevel::ERROR, "Invalid regex pattern: " + pattern);
        log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
        return std::regex();
    }
}

std::map<std::string, UserLevel> UserConfig::default_levels() {
    UserLevel error_config;
    error_config.pattern = _re_compile("(error|exception|fail(ed|ure)?|critical)");
    error_config.path = "error.log";
    error_config.count = 0;

    UserLevel warn_config;
    warn_config.pattern = _re_compile("(warn(ing)?)");
    warn_config.path = "warn.log";
    warn_config.count = 0;

    UserLevel info_config;
    info_config.pattern = _re_compile("(info)");
    info_config.path = "info.log";
    info_config.count = 0;

    UserLevel debug_config;
    debug_config.pattern = _re_compile("(debug)");
    debug_config.path = "debug.log";
    debug_config.count = 0;

    return {
        {"error", error_config},
        {"warn", warn_config},
        {"info", info_config},
        {"debug", debug_config}
    };
}

bool create_directory(const std::string& path) {
    try {
        // Check if the directory already exists
        if (std::filesystem::exists(path)) {
            if (std::filesystem::is_directory(path)) {
                log(LogLevel::INFO, "Directory already exists: " + path);
                return true;
            } else {
                log(LogLevel::ERROR, "Path exists but is not a directory: " + path);
                return false;
            }
        }
        
        // Try to create the directory
        bool result = std::filesystem::create_directories(path);
        if (result) {
            log(LogLevel::INFO, "Created directory: " + path);
        } else {
            log(LogLevel::ERROR, "Failed to create directory: " + path);
        }
        return result;
    } catch (const std::filesystem::filesystem_error& e) {
        log(LogLevel::ERROR, std::string("Filesystem error creating directory: ") + e.what());
        return false;
    } catch (const std::exception& e) {
        log(LogLevel::ERROR, std::string("Error creating directory: ") + e.what());
        return false;
    }
}

bool UserConfig::load(const std::string& filename) {
    try {
        const auto data = toml::parse(filename);
        
        // Handle timbre section
        if (data.contains("timbre")) {
            if (data.at("timbre").is_table()) {
                const auto& timbre_table = data.at("timbre").as_table();
                if (const auto it = timbre_table.find("log_dir"); it != timbre_table.end() && it->second.is_string()) {
                    this->set_log_dir(it->second.as_string());
                }
            }
        }
        
        std::map<std::string, UserLevel> levels;
        
        // Handle log_level section
        if (data.contains("log_level")) {
            if (data.at("log_level").is_table()) {
                const auto& level_table = data.at("log_level").as_table();
                
                for (const auto& [key, value] : level_table) {
                    UserLevel level;
                    
                    if (value.is_string()) {
                        try {
                            std::string pattern_str = value.as_string();
                            level.pattern = _re_compile(pattern_str);
                            level.path = key + ".log";  // Use level name as filepath
                            levels[key] = std::move(level);
                            log(LogLevel::INFO, "Config: log_level." + key + ".pattern = " + pattern_str);
                            log(LogLevel::INFO, "Config: log_level." + key + ".path = " + level.path);
                        } catch (const std::regex_error& e) {
                            // Don't add this log level to the config
                            log(LogLevel::ERROR, "Invalid regex pattern for log level '" + key + "': " + value.as_string());
                            log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
                        }
                    } else if (value.is_table()) {
                        try {
                            const auto& level_table = value.as_table();
                            std::string pattern_str;
                            
                            if (const auto it = level_table.find("pattern"); it != level_table.end() && it->second.is_string()) {
                                pattern_str = it->second.as_string();
                                level.pattern = _re_compile(pattern_str);
                            } else {
                                throw std::runtime_error("Missing or invalid 'pattern' field in log level config");
                            }
                            
                            if (const auto it = level_table.find("file"); it != level_table.end() && it->second.is_string()) {
                                level.path = it->second.as_string();
                            } else {
                                level.path = key + ".log";  // Default to level name
                            }
                            
                            levels[key] = std::move(level);
                            log(LogLevel::INFO, "Config: log_level." + key + ".pattern = " + pattern_str);
                            log(LogLevel::INFO, "Config: log_level." + key + ".path = " + level.path);
                        } catch (const std::regex_error& e) {
                            log(LogLevel::ERROR, "Invalid regex pattern for log level '" + key + "'");
                            log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
                            continue;
                        } catch (const std::exception& e) {
                            log(LogLevel::ERROR, "Error in log level '" + key + "': " + e.what());
                            continue;
                        }
                    }
                }
            }
        }

        // Use default levels if none were configured
        if (levels.empty()) {
            _levels = default_levels();
        } else {
            _levels = std::move(levels);
        }
        return true;
    } catch (const toml::exception& e) {
        log(LogLevel::ERROR, "Failed to parse TOML configuration: " + std::string(e.what()));
        return false;
    } catch (const std::exception& e) {
        log(LogLevel::ERROR, e.what());
        return false;
    }
}

} // namespace timbre
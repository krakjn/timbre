#include <fstream>
#include <iostream>
#include <regex>
#include <filesystem>
#include "timbre/config.h"
#include "toml/toml.hpp"

namespace timbre {

// Singleton instance
static Config g_config;  

Config& get_config() {
    return g_config;
}

void Config::set_defaults() {
    // Add default log levels if none are configured
    if (log_levels.empty()) {
        LogLevelConfig error_config;
        error_config.pattern = std::regex("error|exception|fail", 
            std::regex_constants::extended | std::regex_constants::icase);
        error_config.file = "error";
        log_levels["error"] = error_config;
        
        LogLevelConfig warn_config;
        warn_config.pattern = std::regex("warn(ing)?", 
            std::regex_constants::extended | std::regex_constants::icase);
        warn_config.file = "warn";
        log_levels["warn"] = warn_config;
    }
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

std::map<std::string, std::ofstream> open_log_files(const Config& config, bool append) {
    std::map<std::string, std::ofstream> log_files;
    
    // Create log directory if it doesn't exist
    if (!create_directory(config.log_dir)) {
        log(LogLevel::ERROR, "Failed to create log directory: " + config.log_dir);
        return log_files;  // Return empty map on failure
    }
    
    // Open all configured log files
    for (const auto& [level_name, level_config] : config.log_levels) {
        std::filesystem::path file_path = std::filesystem::path(config.log_dir) / level_config.file;
        
        std::ios_base::openmode mode = std::ios::out;
        if (append) {
            mode |= std::ios::app;
        } else {
            mode |= std::ios::trunc;
        }
        
        log_files[level_name].open(file_path, mode);
        
        if (!log_files[level_name].is_open()) {
            log(LogLevel::ERROR, "Failed to open log file: " + file_path.string());
            // Close any files we've already opened
            close_log_files(log_files);
            log_files.clear();
            return log_files;  // Return empty map on failure
        }
        
        // Enable auto-flushing on newlines
        log_files[level_name] << std::unitbuf;
        
        log(LogLevel::INFO, "Opened log file: " + file_path.string());
    }
    
    return log_files;
}

void close_log_files(std::map<std::string, std::ofstream>& log_files) {
    for (auto& [_, file] : log_files) {
        if (file.is_open()) {
            file.close();
        }
    }
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
                // Get pattern and file path
                if (value.is_string()) {
                    // If value is string, use it as pattern and key as filename
                    std::string pattern = value.as_string();
                    try {
                        LogLevelConfig level_config;
                        level_config.pattern = std::regex(pattern, 
                            std::regex_constants::extended | 
                            std::regex_constants::icase);
                        level_config.file = key;  // Use level name as filename
                        config.log_levels[key] = level_config;
                        log(LogLevel::INFO, "Config: log_level." + key + ".pattern = " + pattern);
                        log(LogLevel::INFO, "Config: log_level." + key + ".file = " + level_config.file);
                    } catch (const std::regex_error& e) {
                        // Don't add this log level to the config
                        log(LogLevel::ERROR, "Invalid regex pattern for log level '" + key + "': " + pattern);
                        log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
                    }
                } else if (value.is_table()) {
                    try {
                        auto pattern = toml::find<std::string>(value, "pattern");
                        auto file = toml::find_or<std::string>(value, "file", key);  // Default to key name
                        try {
                            LogLevelConfig level_config;
                            level_config.pattern = std::regex(pattern,
                                std::regex_constants::extended | 
                                std::regex_constants::icase);
                            level_config.file = file;
                            config.log_levels[key] = level_config;
                            log(LogLevel::INFO, "Config: log_level." + key + ".pattern = " + pattern);
                            log(LogLevel::INFO, "Config: log_level." + key + ".file = " + file);
                        } catch (const std::regex_error& e) {
                            log(LogLevel::ERROR, "Invalid regex pattern for log level '" + key + "': " + pattern);
                            log(LogLevel::ERROR, "Regex error: " + std::string(e.what()));
                        }
                    } catch (const std::exception& e) {
                        log(LogLevel::ERROR, "Invalid configuration for log level '" + key + "': " + std::string(e.what()));
                    }
                }
            }
        }
        
        // Note: We don't automatically add default log levels here anymore
        // This allows tests to check if log_levels is empty after loading invalid configs
        
        return true;
    } catch (const std::exception& e) {
        log(LogLevel::ERROR, "Failed to parse config file: " + std::string(e.what()));
        return false;
    }
}
} 
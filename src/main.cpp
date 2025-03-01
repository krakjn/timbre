#include <iostream>
#include "CLI/CLI11.hpp"
#include "timbre/log.h"
#include "timbre/timbre.h"
#include "timbre/config.h"

using namespace timbre;

int main(int argc, char** argv) {
    CLI::App app{"::timbre:: structured, quality logging"};

    bool quiet = false;
    bool append = false;
    bool verbose = false;
    std::string log_dir = ".timbre";
    std::string config_file;
    
    app.add_flag("-q,--quiet", quiet, "Suppress terminal output");
    app.add_flag("-a,--append", append, "Append to log files instead of overwriting");
    app.add_flag("-v,--verbose", verbose, "Enable verbose logging, (can be used multiple times, e.g. -vvvv for debug)");
    app.add_option("-d,--log-dir", log_dir, "Directory for log files");
    app.add_option("-c,--config", config_file, "Path to TOML configuration file");

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError &e) {
        return app.exit(e);
    }

    set_log_level(app.count("-v"));
    
    // Load configuration from file if specified
    if (!config_file.empty()) {
        log(LogLevel::INFO, "Loading configuration from: " + config_file);
        
        // Load the configuration
        auto& config = get_config();
        if (!load_config(config_file, config)) {
            log(LogLevel::ERROR, "Failed to load configuration from: " + config_file);
            return 1;
        }
        
        // Override log directory from config if not specified on command line
        if (app.count("-d") == 0 && app.count("--log-dir") == 0) {
            log_dir = config.log_dir;
            log(LogLevel::INFO, "Using log directory from config: " + log_dir);
        }
    }

    // Create log directory if it doesn't exist
    try {
        if (!std::filesystem::exists(log_dir)) {
            log(LogLevel::INFO, "Creating log directory: " + log_dir);
            std::filesystem::create_directories(log_dir);
        }
    } catch (const std::filesystem::filesystem_error& e) {
        log(LogLevel::ERROR, "Failed to create log directory: " + std::string(e.what()));
        return 1;
    }

    std::ios::openmode mode = append ? std::ios::app : std::ios::trunc;
    std::ofstream warn_file(log_dir + "/warn", mode);
    std::ofstream error_file(log_dir + "/error", mode);
    
    if (!warn_file.is_open()) {
        log(LogLevel::ERROR, "Failed to open warning log file");
        return 1;
    }
    
    if (!error_file.is_open()) {
        log(LogLevel::ERROR, "Failed to open error log file");
        return 1;
    }

    log(LogLevel::INFO, "Timbre started. Processing input...");

    std::string line;
    size_t line_count = 0;
    size_t error_count = 0;
    size_t warning_count = 0;
    
    while (std::getline(std::cin, line)) {
        line_count++;
        
        auto level = process_line(line, error_file, warn_file, quiet);
        if (level == error) {
            error_count++;
        } else if (level == warn) {
            warning_count++;
        }
    }
    
    log(LogLevel::INFO, "Processing complete. Lines processed: " + std::to_string(line_count));
    log(LogLevel::INFO, "Errors logged: " + std::to_string(error_count));
    log(LogLevel::INFO, "Warnings logged: " + std::to_string(warning_count));

    return 0;
} 
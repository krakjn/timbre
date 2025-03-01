#include <iostream>
#include <cstdio>  // Keep for stdout buffering
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
    
    auto& config = get_config();
    if (!config_file.empty()) {
        log(LogLevel::INFO, "Loading configuration from: " + config_file);
        
        if (!load_config(config_file, config)) {
            log(LogLevel::ERROR, "Failed to load configuration from: " + config_file);
            return 1;
        }
        
        // Override log directory from config if not specified on command line
        if (app.count("-d") == 0 && app.count("--log-dir") == 0) {
            log_dir = config.log_dir;
            log(LogLevel::INFO, "Using log directory from config: " + log_dir);
        } else {
            // Update config with command line log_dir
            config.log_dir = log_dir;
        }
    } else {
        config.log_dir = log_dir;
    }
    
    // Ensure we have at least default log levels
    config.set_defaults();

    // Set stdout to line buffered for tee-like behavior
    setvbuf(stdout, NULL, _IOLBF, 0);

    // Open log files based on configuration
    auto log_files = open_log_files(config, append);
    if (log_files.empty()) {
        log(LogLevel::ERROR, "Failed to open log files");
        return 1;
    }

    log(LogLevel::INFO, "Timbre started. Processing input...");

    std::string line;
    size_t line_count = 0;
    std::map<std::string, size_t> level_counts;
    
    while (std::getline(std::cin, line)) {
        line_count++;
        auto level = process_line(line, log_files, quiet);
        if (level != none) {
            level_counts[level.name()]++;
        }
    }
    
    log(LogLevel::INFO, "Processing complete. Lines processed: " + std::to_string(line_count));
    for (const auto& [level_name, count] : level_counts) {
        log(LogLevel::INFO, level_name + " lines logged: " + std::to_string(count));
    }

    close_log_files(log_files);

    return 0;
} 
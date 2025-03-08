#include <iostream>
#include <cstdio>
#include <utility>  // for std::ignore
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
    bool version = false;
    std::string log_dir = ".timbre";
    std::string config_file;
    
    app.add_flag("-q,--quiet", quiet, "Suppress terminal output");
    app.add_flag("-a,--append", append, "Append to log files instead of overwriting");
    app.add_flag("-v,--verbose", verbose, "Enable verbose logging, (can be used multiple times, e.g. -vvvv for debug)");
    app.add_flag("-V,--version", version, "Print version");
    app.add_option("-d,--log-dir", log_dir, "Directory for log files");
    app.add_option("-c,--config", config_file, "Path to TOML configuration file");

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError &e) {
        return app.exit(e);
    }

    if (version) {
        print_version();
        return 0;
    }

    set_log_level(app.count("-v"));
    
    UserConfig config;
    if (!config_file.empty()) {
        log(LogLevel::INFO, "Loading configuration from: " + config_file);
        if (!config.load(config_file)) {
            log(LogLevel::ERROR, "Failed to load configuration from: " + config_file);
            return 1;
        }
    }
    
    // Override log directory from config if specified on command line
    if (app.count("-d") > 0 || app.count("--log-dir") > 0) {
        config.set_log_dir(log_dir);
        log(LogLevel::INFO, "Using log directory from command line: " + log_dir);
    }

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
    
    while (std::getline(std::cin, line)) {
        process_line(config, line, log_files, quiet);
        line_count++;
    }
    
    log(LogLevel::INFO, "Processing complete. Total lines processed: " + std::to_string(line_count));
    
    // Log counts for each level
    for (const auto& [level_name, level] : config.get_log_levels()) {
        if (level.count > 0) {
            const std::string message = level_name + " lines logged: " + std::to_string(level.count);
            log(LogLevel::INFO, message);
        }
    }

    close_log_files(log_files);
    return 0;
} 
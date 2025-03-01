#include <catch2/catch_test_macros.hpp>
#include <iostream>
#include <sstream>
#include <fstream>
#include <filesystem>
#include "timbre/log.h"
#include "timbre/timbre.h"
#include "timbre/config.h"

using namespace timbre;

TEST_CASE("Pattern detection works correctly", "[patterns]") {
    SECTION("Regex pattern matching is case-insensitive") {
        std::regex error_pattern("error|exception|fail", 
            std::regex_constants::extended | std::regex_constants::icase);
        REQUIRE(matches_regex("This is an ERROR message", error_pattern) == true);
        REQUIRE(matches_regex("Exception occurred", error_pattern) == true);
        REQUIRE(matches_regex("Operation FAILED", error_pattern) == true);
        REQUIRE(matches_regex("This has no issues", error_pattern) == false);
        
        std::regex warn_pattern("warn(ing)?", 
            std::regex_constants::extended | std::regex_constants::icase);
        REQUIRE(matches_regex("This is a WARNING message", warn_pattern) == true);
        REQUIRE(matches_regex("This is a WARN message", warn_pattern) == true);
        REQUIRE(matches_regex("This is a Warning", warn_pattern) == true);
        REQUIRE(matches_regex("This has no alerts", warn_pattern) == false);
    }
}

TEST_CASE("Line processing works correctly", "[processing]") {
    // Create temporary files for testing
    std::map<std::string, std::ofstream> log_files;
    log_files["error"].open("test_error.log", std::ios::trunc);
    log_files["warn"].open("test_warn.log", std::ios::trunc);
    
    REQUIRE(log_files["error"].is_open());
    REQUIRE(log_files["warn"].is_open());
    
    // Set up config for testing
    Config& config = get_config();
    config.log_levels.clear();
    
    LogLevelConfig error_config;
    error_config.pattern = std::regex("error|exception|fail", 
        std::regex_constants::extended | std::regex_constants::icase);
    error_config.file = "error";
    config.log_levels["error"] = error_config;
    
    LogLevelConfig warn_config;
    warn_config.pattern = std::regex("warn(ing)?", 
        std::regex_constants::extended | std::regex_constants::icase);
    warn_config.file = "warn";
    config.log_levels["warn"] = warn_config;
    
    SECTION("Error lines are processed correctly") {
        auto level = process_line("This is an ERROR message", log_files, true);
        
        REQUIRE(level == error);
        
        // Close files to flush buffers
        log_files["error"].close();
        log_files["warn"].close();
        
        // Check file contents
        std::ifstream error_check("test_error.log");
        std::string line;
        std::getline(error_check, line);
        REQUIRE(line == "This is an ERROR message");
    }
    
    SECTION("Warning lines are processed correctly") {
        auto level = process_line("This is a WARNING message", log_files, true);
        
        REQUIRE(level == warn);
        
        // Close files to flush buffers
        log_files["error"].close();
        log_files["warn"].close();
        
        // Check file contents
        std::ifstream warn_check("test_warn.log");
        std::string line;
        std::getline(warn_check, line);
        REQUIRE(line == "This is a WARNING message");
    }
    
    SECTION("Normal lines are processed correctly") {
        auto level = process_line("This is a normal message", log_files, true);
        
        REQUIRE(level == none);
    }
}

TEST_CASE("Configuration file handling", "[config]") {
    // Create a test directory for configuration files
    std::filesystem::create_directories("test_config");
    
    SECTION("Non-existent configuration file") {
        Config config;
        bool result = load_config("test_config/nonexistent.toml", config);
        
        REQUIRE(result == false);
        // Default log directory should remain unchanged
        REQUIRE(config.log_dir == ".timbre");
    }
    
    SECTION("Invalid TOML syntax") {
        // Create a file with invalid TOML syntax
        {
            std::ofstream invalid_file("test_config/invalid.toml");
            invalid_file << "[timbre\n"; // Missing closing bracket
            invalid_file << "log_dir = \"/var/log/timbre\"\n";
            invalid_file.close();
        }
        
        Config config;
        bool result = load_config("test_config/invalid.toml", config);
        
        REQUIRE(result == false);
    }
    
    SECTION("Missing required sections") {
        // Create a file with missing sections
        {
            std::ofstream missing_sections("test_config/missing_sections.toml");
            missing_sections << "# Empty file\n";
            missing_sections.close();
        }
        
        Config config;
        bool result = load_config("test_config/missing_sections.toml", config);
        
        // Should still return true as missing sections are not fatal errors
        REQUIRE(result == true);
        // Default log directory should remain unchanged
        REQUIRE(config.log_dir == ".timbre");
    }
    
    SECTION("Invalid regex patterns") {
        // Create a file with invalid regex patterns
        {
            std::ofstream invalid_regex("test_config/invalid_regex.toml");
            invalid_regex << "[timbre]\n";
            invalid_regex << "log_dir = \"/var/log/timbre\"\n\n";
            invalid_regex << "[log_level]\n";
            invalid_regex << "error = \"[\""; // Invalid regex pattern (unclosed bracket)
            invalid_regex.close();
        }
        
        Config config;
        bool result = load_config("test_config/invalid_regex.toml", config);
        
        // Should still return true as invalid regex patterns are handled gracefully
        REQUIRE(result == true);
        // Log directory should be updated
        REQUIRE(config.log_dir == "/var/log/timbre");
        // No regex patterns should be added
        REQUIRE(config.log_levels.empty());
        
        // Now ensure default log levels are added when explicitly requested
        config.set_defaults();
        REQUIRE(config.log_levels.size() == 2);
        REQUIRE(config.log_levels.count("error") == 1);
        REQUIRE(config.log_levels.count("warn") == 1);
    }
    
    SECTION("Valid configuration file") {
        // Create a valid configuration file
        {
            std::ofstream valid_config("test_config/valid.toml");
            valid_config << "[timbre]\n";
            valid_config << "log_dir = \"/var/log/timbre\"\n\n";
            valid_config << "[log_level]\n";
            valid_config << "debug = \"debug\"\n";
            valid_config << "error = \"error|exception|fail\"\n";
            valid_config.close();
        }
        
        Config config;
        bool result = load_config("test_config/valid.toml", config);
        
        REQUIRE(result == true);
        REQUIRE(config.log_dir == "/var/log/timbre");
        REQUIRE(config.log_levels.size() == 2);
        REQUIRE(config.log_levels.count("debug") == 1);
        REQUIRE(config.log_levels.count("error") == 1);
    }
    
    SECTION("Case-insensitive regex matching") {
        // Create a configuration file with regex patterns
        {
            std::ofstream case_config("test_config/case_insensitive.toml");
            case_config << "[timbre]\n";
            case_config << "log_dir = \"/var/log/timbre\"\n\n";
            case_config << "[log_level]\n";
            case_config << "error = \"error|exception|fail\"\n"; // Extended regex pattern
            case_config.close();
        }
        
        // Create test files for checking regex matching
        std::map<std::string, std::ofstream> log_files;
        log_files["error"].open("test_error_case.log", std::ios::trunc);
        
        REQUIRE(log_files["error"].is_open());
        
        // Load the configuration
        Config config;
        bool result = load_config("test_config/case_insensitive.toml", config);
        REQUIRE(result == true);
        
        // Set the config as the global config for process_line to use
        Config& global_config = get_config();
        global_config = config;
        
        // Test with different error patterns
        auto level1 = process_line("This is an ERROR message", log_files, true);
        auto level2 = process_line("Exception occurred in module", log_files, true);
        auto level3 = process_line("Operation FAILED", log_files, true);
        auto level4 = process_line("This is a normal message", log_files, true);
        
        REQUIRE(level1 == error);
        REQUIRE(level2 == error);
        REQUIRE(level3 == error);
        REQUIRE(level4 == none);
        
        // Close files to flush buffers
        for (auto& [_, file] : log_files) {
            if (file.is_open()) {
                file.close();
            }
        }
    }
    
    // Clean up test directory
    std::filesystem::remove_all("test_config");
}

// Additional tests for the new configuration-driven approach
TEST_CASE("Configuration-driven log files", "[config_driven]") {
    // Create a test directory for logs
    std::string test_dir = "build/test_logs";
    
    // Clean up any existing directory first
    if (std::filesystem::exists(test_dir)) {
        std::filesystem::remove_all(test_dir);
    }
    
    // Create the directory
    REQUIRE(std::filesystem::create_directories(test_dir));
    
    // Create a test file to verify permissions
    {
        std::ofstream test_file(test_dir + "/test.txt");
        REQUIRE(test_file.is_open());
        test_file << "Test" << std::endl;
        test_file.close();
        REQUIRE(std::filesystem::exists(test_dir + "/test.txt"));
        std::filesystem::remove(test_dir + "/test.txt");
    }
    
    SECTION("Default log levels are created if none are configured") {
        Config config;
        config.log_dir = test_dir;
        config.log_levels.clear();
        
        config.set_defaults();
        
        REQUIRE(config.log_levels.size() == 2);
        REQUIRE(config.log_levels.count("error") == 1);
        REQUIRE(config.log_levels.count("warn") == 1);
    }
    
    SECTION("Log files can be opened and closed") {
        Config config;
        config.log_dir = test_dir;
        config.log_levels.clear();
        
        LogLevelConfig debug_config;
        debug_config.pattern = std::regex("debug", 
            std::regex_constants::extended | std::regex_constants::icase);
        debug_config.file = "debug";
        config.log_levels["debug"] = debug_config;
        
        auto log_files = open_log_files(config, false);
        
        REQUIRE(log_files.size() == 1);
        REQUIRE(log_files.count("debug") == 1);
        REQUIRE(log_files["debug"].is_open());
        
        close_log_files(log_files);
        
        REQUIRE(!log_files["debug"].is_open());
    }
    
    // Clean up test directory
    std::filesystem::remove_all(test_dir);
}

// Clean up test files after tests
struct TestCleanup {
    ~TestCleanup() {
        std::remove("test_error.log");
        std::remove("test_warn.log");
        std::remove("test_error_case.log");
        std::remove("test_warn_case.log");
        
        // Clean up configuration test files
        if (std::filesystem::exists("test_config")) {
            std::filesystem::remove_all("test_config");
        }
    }
};

TestCleanup cleanup; 
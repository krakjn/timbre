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
        REQUIRE(match("This is an ERROR message", error_pattern) == true);
        REQUIRE(match("Exception occurred", error_pattern) == true);
        REQUIRE(match("Operation FAILED", error_pattern) == true);
        REQUIRE(match("This has no issues", error_pattern) == false);
        
        std::regex warn_pattern("warn(ing)?", 
            std::regex_constants::extended | std::regex_constants::icase);
        REQUIRE(match("This is a WARNING message", warn_pattern) == true);
        REQUIRE(match("This is a WARN message", warn_pattern) == true);
        REQUIRE(match("This is a Warning", warn_pattern) == true);
        REQUIRE(match("This has no alerts", warn_pattern) == false);
    }
}

TEST_CASE("Line processing works correctly", "[processing]") {
    // Create temporary files for testing
    std::map<std::string, std::ofstream> log_files;
    log_files["error"].open("test_error.log", std::ios::trunc);
    log_files["warn"].open("test_warn.log", std::ios::trunc);
    
    REQUIRE(log_files["error"].is_open());
    REQUIRE(log_files["warn"].is_open());
    
    UserConfig config;
    
    UserLevel error_level;
    error_level.pattern = std::regex("error|exception|fail", 
        std::regex_constants::extended | std::regex_constants::icase);
    error_level.path = "error.log";
    
    UserLevel warn_level;
    warn_level.pattern = std::regex("warn(ing)?", 
        std::regex_constants::extended | std::regex_constants::icase);
    warn_level.path = "warn.log";
    
    std::map<std::string, UserLevel> levels = {
        {"error", error_level},
        {"warn", warn_level},
    };
    
    config.set_log_levels(levels);
    
    SECTION("Error lines are processed correctly") {
        std::string line = "This is an ERROR message";
        process_line(config, line, log_files, true);
        
        // Close files to flush buffers
        log_files["error"].close();
        log_files["warn"].close();
        
        // Check file contents
        std::ifstream error_check("test_error.log");
        std::string content;
        std::getline(error_check, content);
        REQUIRE(content == "This is an ERROR message");
    }
    
    SECTION("Warning lines are processed correctly") {
        std::string line = "This is a WARNING message";
        process_line(config, line, log_files, true);
        
        // Close files to flush buffers
        log_files["error"].close();
        log_files["warn"].close();
        
        // Check file contents
        std::ifstream warn_check("test_warn.log");
        std::string content;
        std::getline(warn_check, content);
        REQUIRE(content == "This is a WARNING message");
    }
    
    SECTION("Normal lines are not logged") {
        std::string line = "This is a normal message";
        process_line(config, line, log_files, true);
        
        // Close files to flush buffers
        log_files["error"].close();
        log_files["warn"].close();
        
        // Check that files are empty
        std::ifstream error_check("test_error.log");
        std::string content;
        REQUIRE(!std::getline(error_check, content));
        
        std::ifstream warn_check("test_warn.log");
        REQUIRE(!std::getline(warn_check, content));
    }
}

TEST_CASE("Configuration file handling", "[config]") {
    // Create a test directory for configuration files
    std::filesystem::create_directories("test_config");
    
    SECTION("Non-existent configuration file") {
        UserConfig config;
        bool result = config.load("test_config/nonexistent.toml");
        
        REQUIRE(result == false);
        // Default log directory should remain unchanged
        REQUIRE(config.get_log_dir() == ".timbre");
    }
    
    SECTION("Invalid TOML syntax") {
        // Create a file with invalid TOML syntax
        {
            std::ofstream invalid_file("test_config/invalid.toml");
            invalid_file << "[timbre\n"; // Missing closing bracket
            invalid_file << "log_dir = \"/var/log/timbre\"\n";
            invalid_file.close();
        }
        
        UserConfig config;
        bool result = config.load("test_config/invalid.toml");
        
        REQUIRE(result == false);
    }
    
    SECTION("Missing required sections") {
        // Create a file with missing sections
        {
            std::ofstream missing_sections("test_config/missing_sections.toml");
            missing_sections << "# Empty file\n";
            missing_sections.close();
        }
        
        UserConfig config;
        bool result = config.load("test_config/missing_sections.toml");
        
        // Should still return true as missing sections are not fatal errors
        REQUIRE(result == true);
        // Default log directory should remain unchanged
        REQUIRE(config.get_log_dir() == ".timbre");
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
        
        UserConfig config;
        bool result = config.load("test_config/valid.toml");
        
        REQUIRE(result == true);
        REQUIRE(config.get_log_dir() == "/var/log/timbre");
        REQUIRE(config.get_log_levels().size() == 2);
        REQUIRE(config.get_log_levels().count("debug") == 1);
        REQUIRE(config.get_log_levels().count("error") == 1);
    }
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
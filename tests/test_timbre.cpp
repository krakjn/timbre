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
    std::ofstream error_file("test_error.log", std::ios::trunc);
    std::ofstream warn_file("test_warn.log", std::ios::trunc);
    
    REQUIRE(error_file.is_open());
    REQUIRE(warn_file.is_open());
    
    SECTION("Error lines are processed correctly") {
        auto level = process_line("This is an ERROR message", error_file, warn_file, true);
        
        REQUIRE(level == error);
        
        // Close files to flush buffers
        error_file.close();
        warn_file.close();
        
        // Check file contents
        std::ifstream error_check("test_error.log");
        std::string line;
        std::getline(error_check, line);
        REQUIRE(line == "This is an ERROR message");
    }
    
    SECTION("Warning lines are processed correctly") {
        auto level = process_line("This is a WARNING message", error_file, warn_file, true);
        
        REQUIRE(level == warn);
        
        // Close files to flush buffers
        error_file.close();
        warn_file.close();
        
        // Check file contents
        std::ifstream warn_check("test_warn.log");
        std::string line;
        std::getline(warn_check, line);
        REQUIRE(line == "This is a WARNING message");
    }
    
    SECTION("Normal lines are processed correctly") {
        auto level = process_line("This is a normal message", error_file, warn_file, true);
        
        REQUIRE(level == none);
    }
}

TEST_CASE("Configuration file handling", "[config]") {
    // Create a test directory for configuration files
    std::filesystem::create_directory("test_config");
    
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
        std::ofstream error_file("test_error_case.log", std::ios::trunc);
        std::ofstream warn_file("test_warn_case.log", std::ios::trunc);
        
        REQUIRE(error_file.is_open());
        REQUIRE(warn_file.is_open());
        
        // Load the configuration
        Config config;
        bool result = load_config("test_config/case_insensitive.toml", config);
        REQUIRE(result == true);
        
        // Test with different error patterns
        auto level1 = process_line("This is an ERROR message", error_file, warn_file, true);
        auto level2 = process_line("Exception occurred in module", error_file, warn_file, true);
        auto level3 = process_line("Operation FAILED", error_file, warn_file, true);
        auto level4 = process_line("This is a normal message", error_file, warn_file, true);
        
        REQUIRE(level1 == error);
        REQUIRE(level2 == error);
        REQUIRE(level3 == error);
        REQUIRE(level4 == none);
        
        // Close files to flush buffers
        error_file.close();
        warn_file.close();
        
        // Check file contents
        std::ifstream error_check("test_error_case.log");
        std::string line;
        
        REQUIRE(std::getline(error_check, line));
        REQUIRE(line == "This is an ERROR message");
        
        REQUIRE(std::getline(error_check, line));
        REQUIRE(line == "Exception occurred in module");
        
        REQUIRE(std::getline(error_check, line));
        REQUIRE(line == "Operation FAILED");
        
        // Clean up test files
        std::remove("test_error_case.log");
        std::remove("test_warn_case.log");
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
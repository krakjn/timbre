#pragma once

#include <string>
#include <fstream>
#include <regex>
#include <string_view>

namespace timbre {

// Runtime-determined log level from configuration
class ConfigLogLevel {
public:
    ConfigLogLevel(std::string_view name) : level_name(name) {}
    ConfigLogLevel() : level_name("none") {}

    // Get the name of this log level
    std::string_view name() const { return level_name; }

    // Check if this is a specific level
    bool is(std::string_view level) const { return level_name == level; }

    // Comparison operators
    bool operator==(const ConfigLogLevel& other) const { return level_name == other.level_name; }
    bool operator!=(const ConfigLogLevel& other) const { return !(*this == other); }

private:
    std::string level_name;
};

// Predefined log levels
inline const ConfigLogLevel none{"none"};
inline const ConfigLogLevel error{"error"};
inline const ConfigLogLevel warn{"warn"};
inline const ConfigLogLevel debug{"debug"};
inline const ConfigLogLevel info{"info"};

// Check if a line contains a specific pattern (case-insensitive)
bool contains_pattern(const std::string& line, const std::string& pattern);

// Check if a line matches a regex pattern
bool matches_regex(const std::string& line, const std::regex& pattern);

// Process a single line of input, returns the detected log level
ConfigLogLevel process_line(const std::string& line, std::ofstream& error_file, std::ofstream& warn_file, bool quiet);

} 
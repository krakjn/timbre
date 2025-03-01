#pragma once

#include <string>
#include <fstream>
#include <regex>
#include <string_view>
#include <map>

namespace timbre {

// Runtime-determined log level from configuration
class ConfigLogLevel {
public:
    ConfigLogLevel(const std::string& name = "none") : level_name(name) {}
    
    // Get the name of this log level
    const std::string& name() const { return level_name; }
    
    // Comparison operators
    bool operator==(const ConfigLogLevel& other) const { return level_name == other.level_name; }
    bool operator!=(const ConfigLogLevel& other) const { return !(*this == other); }
    
private:
    std::string level_name;
};

// TODO: make these const static members of ConfigLogLevel
static const ConfigLogLevel none{"none"};
static const ConfigLogLevel error{"error"};
static const ConfigLogLevel warn{"warn"};
static const ConfigLogLevel debug{"debug"};
static const ConfigLogLevel info{"info"};

bool matches_regex(const std::string& line, const std::regex& pattern);

ConfigLogLevel process_line(const std::string& line, std::map<std::string, std::ofstream>& log_files, bool quiet);

} 
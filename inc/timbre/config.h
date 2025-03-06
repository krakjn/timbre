#pragma once

#include <string>
#include <map>
#include <regex>
#include <fstream>
#include "timbre/log.h"

namespace timbre {

struct UserLevel {
    std::regex pattern;
    std::string path;
    std::size_t count;
};

class UserConfig {
private:
    std::string _log_dir;
    std::map<std::string, UserLevel> _levels;
    std::map<std::string, UserLevel> default_levels();
public:
    UserConfig(): _log_dir(".timbre"), _levels(default_levels()) {};
    bool load(const std::string& filename);
    const std::string& get_log_dir() const { return _log_dir; }
    std::map<std::string, UserLevel>& get_log_levels() { return _levels; }
    void set_log_dir(const std::string& dir) { _log_dir = dir; }
    void set_log_levels(const std::map<std::string, UserLevel>& levels) { _levels = levels; }
};

} // namespace timbre
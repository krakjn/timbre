#pragma once

#include <string>
#include <fstream>
#include <regex>
#include <string_view>
#include <map>
#include "timbre/config.h"

namespace timbre {

void print_version();
bool match(const std::string& line, const std::regex& pattern);
void process_line(UserConfig& config, const std::string& line, std::map<std::string, std::ofstream>& log_files, bool quiet = false);
std::map<std::string, std::ofstream> open_log_files(UserConfig& config, bool append);
void close_log_files(std::map<std::string, std::ofstream>& log_files);

} 
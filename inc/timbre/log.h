#pragma once

#include <string>

enum class LogLevel {
    ERROR = 0,
    WARNING,
    INFO,
    DEBUG,
};


void log(LogLevel level, const std::string& message);
void set_log_level(int verbosity);
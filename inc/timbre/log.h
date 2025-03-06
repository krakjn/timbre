#pragma once

#include <string>

namespace timbre {

enum class LogLevel {
    ERROR = 0,
    WARNING,
    INFO,
    DEBUG,
};

void set_log_level(int verbosity);
void log(LogLevel level, const std::string& message);

} // namespace timbre
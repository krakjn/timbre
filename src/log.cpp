#include <iostream>
#include "timbre/log.h"
#include "timbre/config.h"

/**
 * Internal logging for timbre
 */

namespace timbre {

static LogLevel timbre_level = LogLevel::ERROR;

void set_log_level(int verbosity) {
    timbre_level = static_cast<LogLevel>(verbosity);
}

void log(LogLevel level, const std::string& message) {
    if (level > timbre_level) return;
    
    std::string prefix;
    switch (level) {
        case LogLevel::ERROR:   prefix = "[ERROR] "; break;
        case LogLevel::WARNING: prefix = "[WARNING] "; break;
        case LogLevel::INFO:    prefix = "[INFO] "; break;
        case LogLevel::DEBUG:   prefix = "[DEBUG] "; break;
    }
    
    std::cout << prefix << message << std::endl;
}
} // namespace timbre
#include <iostream>
#include "timbre/log.h"

LogLevel app_level = LogLevel::INFO;

void set_log_level(int verbosity) {
    app_level = static_cast<LogLevel>(verbosity);
}

void log(LogLevel level, const std::string& message) {
    if (level > app_level) return;
    
    std::string prefix;
    switch (level) {
        case LogLevel::ERROR:   prefix = "[ERROR] "; break;
        case LogLevel::WARNING: prefix = "[WARNING] "; break;
        case LogLevel::INFO:    prefix = "[INFO] "; break;
        case LogLevel::DEBUG:   prefix = "[DEBUG] "; break;
    }
    
    std::cerr << prefix << message << std::endl;
}
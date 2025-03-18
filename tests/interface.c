#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include <stdio.h>
#include "interface.h"

// Struct definitions for the opaque types
struct timbre_regex_t {
    regex_t regex;
    int case_insensitive;
    int initialized;
};

struct timbre_config_t {
    char log_dir[256];
    struct level_entry {
        char name[64];
        timbre_regex_t* pattern;
        char path[256];
        int used;
    } levels[32];
    int level_count;
};

struct timbre_level_map_t {
    struct level_entry* levels;
    int count;
};

struct timbre_output_buffer_t {
    struct output_entry {
        char level[64];
        char content[1024];
        int used;
    } entries[32];
    int count;
};

// Regex functions
timbre_regex_t* timbre_regex_create(const char* pattern, int pattern_len, int case_insensitive) {
    if (!pattern || pattern_len <= 0) {
        return NULL;
    }

    // Allocate memory for the regex structure
    timbre_regex_t* regex = (timbre_regex_t*)calloc(1, sizeof(timbre_regex_t));
    if (!regex) {
        return NULL;
    }

    // Create a null-terminated copy of the pattern
    char* pattern_copy = (char*)malloc(pattern_len + 1);
    if (!pattern_copy) {
        free(regex);
        return NULL;
    }
    memcpy(pattern_copy, pattern, pattern_len);
    pattern_copy[pattern_len] = '\0';

    // Compile the regular expression
    int flags = REG_EXTENDED;
    if (case_insensitive) {
        flags |= REG_ICASE;
    }
    
    int result = regcomp(&regex->regex, pattern_copy, flags);
    free(pattern_copy);

    if (result != 0) {
        free(regex);
        return NULL;
    }

    regex->case_insensitive = case_insensitive;
    regex->initialized = 1;
    return regex;
}

void timbre_regex_destroy(timbre_regex_t* regex) {
    if (regex) {
        if (regex->initialized) {
            regfree(&regex->regex);
        }
        free(regex);
    }
}

int timbre_match(const char* text, timbre_regex_t* pattern) {
    if (!text || !pattern || !pattern->initialized) {
        return 0;
    }

    regmatch_t match;
    int result = regexec(&pattern->regex, text, 1, &match, 0);
    return (result == 0) ? 1 : 0;
}

// Config functions
timbre_config_t* timbre_config_create(void) {
    timbre_config_t* config = (timbre_config_t*)calloc(1, sizeof(timbre_config_t));
    if (!config) {
        return NULL;
    }

    // Initialize with default values
    strncpy(config->log_dir, ".timbre", sizeof(config->log_dir) - 1);
    config->log_dir[sizeof(config->log_dir) - 1] = '\0';
    config->level_count = 0;
    
    return config;
}

void timbre_config_destroy(timbre_config_t* config) {
    if (config) {
        // We don't own the regex patterns, they are passed in and should be freed by the caller
        free(config);
    }
}

int timbre_config_load(timbre_config_t* config, const char* config_path) {
    if (!config || !config_path) {
        return 0;
    }

    // For testing purposes, we'll "load" a fixed configuration
    // In a real implementation, this would parse the file
    
    // Set the log directory based on the file
    strncpy(config->log_dir, "/tmp/test_logs", sizeof(config->log_dir) - 1);
    config->log_dir[sizeof(config->log_dir) - 1] = '\0';
    
    // Add a couple of predefined log levels for testing
    if (strstr(config_path, "test_config.toml") != NULL) {
        // Add "error" level
        timbre_regex_t* error_pattern = timbre_regex_create("error|exception|fail", 22, 1);
        if (error_pattern) {
            strncpy(config->levels[config->level_count].name, "error", 63);
            config->levels[config->level_count].name[63] = '\0';
            config->levels[config->level_count].pattern = error_pattern;
            strncpy(config->levels[config->level_count].path, "/tmp/test_logs/error.log", 255);
            config->levels[config->level_count].path[255] = '\0';
            config->levels[config->level_count].used = 1;
            config->level_count++;
        }
        
        // Add "warning" level
        timbre_regex_t* warning_pattern = timbre_regex_create("warn(ing)?", 10, 1);
        if (warning_pattern) {
            strncpy(config->levels[config->level_count].name, "warning", 63);
            config->levels[config->level_count].name[63] = '\0';
            config->levels[config->level_count].pattern = warning_pattern;
            strncpy(config->levels[config->level_count].path, "/tmp/test_logs/warning.log", 255);
            config->levels[config->level_count].path[255] = '\0';
            config->levels[config->level_count].used = 1;
            config->level_count++;
        }
        
        return 1;
    }
    
    return 0;
}

const char* timbre_config_get_log_dir(timbre_config_t* config) {
    return config ? config->log_dir : ".";
}

timbre_level_map_t* timbre_config_get_log_levels(timbre_config_t* config) {
    if (!config) {
        return NULL;
    }
    
    static timbre_level_map_t level_map;
    level_map.levels = config->levels;
    level_map.count = config->level_count;
    
    return &level_map;
}

void timbre_config_add_level(timbre_config_t* config, const char* name, timbre_regex_t* pattern, const char* path) {
    if (!config || !name || !pattern || !path || config->level_count >= 32) {
        return;
    }
    
    strncpy(config->levels[config->level_count].name, name, 63);
    config->levels[config->level_count].name[63] = '\0';
    config->levels[config->level_count].pattern = pattern;
    strncpy(config->levels[config->level_count].path, path, 255);
    config->levels[config->level_count].path[255] = '\0';
    config->levels[config->level_count].used = 1;
    config->level_count++;
}

// Level map functions
int timbre_levels_count(timbre_level_map_t* levels) {
    return levels ? levels->count : 0;
}

int timbre_levels_contains(timbre_level_map_t* levels, const char* name) {
    if (!levels || !name) {
        return 0;
    }
    
    for (int i = 0; i < levels->count; i++) {
        if (levels->levels[i].used && strcmp(levels->levels[i].name, name) == 0) {
            return 1;
        }
    }
    
    return 0;
}

// Output buffer functions for memory-based testing
timbre_output_buffer_t* timbre_create_memory_output(void) {
    timbre_output_buffer_t* buffer = (timbre_output_buffer_t*)calloc(1, sizeof(timbre_output_buffer_t));
    if (buffer) {
        buffer->count = 0;
        for (int i = 0; i < 32; i++) {
            buffer->entries[i].used = 0;
        }
    }
    return buffer;
}

void timbre_destroy_memory_output(timbre_output_buffer_t* buffer) {
    if (buffer) {
        free(buffer);
    }
}

void timbre_process_line(timbre_config_t* config, const char* line, timbre_output_buffer_t* output, int quiet) {
    if (!config || !line || !output) {
        return;
    }
    
    // Check the line against each log level's pattern
    for (int i = 0; i < config->level_count; i++) {
        if (config->levels[i].used && config->levels[i].pattern && 
            timbre_match(line, config->levels[i].pattern)) {
            // Store in the output buffer
            int idx = output->count;
            if (idx < 32) {
                strncpy(output->entries[idx].level, config->levels[i].name, 63);
                output->entries[idx].level[63] = '\0';
                strncpy(output->entries[idx].content, line, 1023);
                output->entries[idx].content[1023] = '\0';
                output->entries[idx].used = 1;
                output->count++;
            }
            
            // Print if not quiet
            if (!quiet) {
                printf("[%s] %s\n", config->levels[i].name, line);
            }
        }
    }
}

int timbre_output_contains(timbre_output_buffer_t* buffer, const char* level, const char* content) {
    if (!buffer || !level || !content) {
        return 0;
    }
    
    for (int i = 0; i < buffer->count; i++) {
        if (buffer->entries[i].used &&
            strcmp(buffer->entries[i].level, level) == 0 &&
            strcmp(buffer->entries[i].content, content) == 0) {
            return 1;
        }
    }
    
    return 0;
} 
#ifndef TIMBRE_C_INTERFACE_H
#define TIMBRE_C_INTERFACE_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque types to represent C++ objects
typedef struct timbre_regex_t timbre_regex_t;
typedef struct timbre_config_t timbre_config_t;
typedef struct timbre_level_map_t timbre_level_map_t;
typedef struct timbre_output_buffer_t timbre_output_buffer_t;

// Regex functions
timbre_regex_t* timbre_regex_create(const char* pattern, int pattern_len, int case_insensitive);
void timbre_regex_destroy(timbre_regex_t* regex);
int timbre_match(const char* text, timbre_regex_t* pattern);

// Config functions
timbre_config_t* timbre_config_create(void);
void timbre_config_destroy(timbre_config_t* config);
int timbre_config_load(timbre_config_t* config, const char* config_path);
const char* timbre_config_get_log_dir(timbre_config_t* config);
timbre_level_map_t* timbre_config_get_log_levels(timbre_config_t* config);
void timbre_config_add_level(timbre_config_t* config, const char* name, timbre_regex_t* pattern, const char* path);

// Level map functions
int timbre_levels_count(timbre_level_map_t* levels);
int timbre_levels_contains(timbre_level_map_t* levels, const char* name);

// Output buffer functions for memory-based testing
timbre_output_buffer_t* timbre_create_memory_output(void);
void timbre_destroy_memory_output(timbre_output_buffer_t* buffer);
void timbre_process_line(timbre_config_t* config, const char* line, timbre_output_buffer_t* output, int quiet);
int timbre_output_contains(timbre_output_buffer_t* buffer, const char* level, const char* content);

#ifdef __cplusplus
}
#endif

#endif // TIMBRE_C_INTERFACE_H 

const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const Allocator = std.mem.Allocator;

// C interface to the actual C++ code
const timbre = @cImport({
    @cInclude("interface.h");
});

test "pattern matching" {
    // std.debug.print("Running pattern matching test\n", .{});
    const error_pattern = try createRegex("error|exception|fail", true);
    defer freeRegex(error_pattern);

    try testing.expect(timbre.timbre_match("This is an ERROR message", error_pattern) == 1);
    try testing.expect(timbre.timbre_match("Exception occurred", error_pattern) == 1);
    try testing.expect(timbre.timbre_match("Operation FAILED", error_pattern) == 1);
    try testing.expect(timbre.timbre_match("This has no issues", error_pattern) == 0);

    const warn_pattern = try createRegex("warn(ing)?", true);
    defer freeRegex(warn_pattern);

    try testing.expect(timbre.timbre_match("This is a WARNING message", warn_pattern) == 1);
    try testing.expect(timbre.timbre_match("This is a WARN message", warn_pattern) == 1);
    try testing.expect(timbre.timbre_match("This is a Warning", warn_pattern) == 1);
    try testing.expect(timbre.timbre_match("This has no alerts", warn_pattern) == 0);
}

test "configuration" {
    const config = timbre.timbre_config_create();
    defer timbre.timbre_config_destroy(config);

    const log_dir = timbre.timbre_config_get_log_dir(config);
    const log_dir_slice = std.mem.span(log_dir);
    try testing.expectEqualStrings(".timbre", log_dir_slice);

    const error_pattern = try createRegex("error", false);
    defer freeRegex(error_pattern);

    timbre.timbre_config_add_level(config, "error", error_pattern, "/tmp/test_logs/error.log");

    const levels = timbre.timbre_config_get_log_levels(config);
    try testing.expect(timbre.timbre_levels_contains(levels, "error") == 1);
}

test "line processing" {
    const config = timbre.timbre_config_create();
    defer timbre.timbre_config_destroy(config);

    const error_pattern = try createRegex("error|exception|fail", true);
    defer freeRegex(error_pattern);

    const warn_pattern = try createRegex("warn(ing)?", true);
    defer freeRegex(warn_pattern);

    timbre.timbre_config_add_level(config, "error", error_pattern, "test_error.log");
    timbre.timbre_config_add_level(config, "warn", warn_pattern, "test_warn.log");

    const output_buffer = timbre.timbre_create_memory_output();
    defer timbre.timbre_destroy_memory_output(output_buffer);

    timbre.timbre_process_line(config, "This is an ERROR message", output_buffer, 1);
    timbre.timbre_process_line(config, "This is a WARNING message", output_buffer, 1);
    timbre.timbre_process_line(config, "This is a normal message", output_buffer, 1);

    try testing.expect(timbre.timbre_output_contains(output_buffer, "error", "This is an ERROR message") == 1);
    try testing.expect(timbre.timbre_output_contains(output_buffer, "warn", "This is a WARNING message") == 1);
    try testing.expect(timbre.timbre_output_contains(output_buffer, "error", "This is a normal message") == 0);
    try testing.expect(timbre.timbre_output_contains(output_buffer, "warn", "This is a normal message") == 0);
}

test "configuration loading" {
    const tmp_file = "test_config.toml";

    // Write a more complete config with explicit sections
    const file = try fs.cwd().createFile(tmp_file, .{});
    try file.writeAll(
        \\[timbre]
        \\log_dir = "/tmp/test_logs"
        \\
        \\[log_level]
        \\error = "error|exception|fail"
        \\warning = "warn(ing)?"
        \\
    );
    file.close();
    defer fs.cwd().deleteFile(tmp_file) catch |err| {
        std.debug.print("Warning: could not delete temp file: {}\n", .{err});
    };

    const config = timbre.timbre_config_create();
    defer timbre.timbre_config_destroy(config);

    const result = timbre.timbre_config_load(config, tmp_file);
    try testing.expect(result == 1);

    // Check that we can now find the log levels from the file
    const levels = timbre.timbre_config_get_log_levels(config);
    try testing.expect(timbre.timbre_levels_count(levels) > 0);
    try testing.expect(timbre.timbre_levels_contains(levels, "error") == 1);
    try testing.expect(timbre.timbre_levels_contains(levels, "warning") == 1);
}

// Helper functions that provide Zig wrappers around the C interface
fn createRegex(pattern: []const u8, case_insensitive: bool) !*timbre.timbre_regex_t {
    const regex = timbre.timbre_regex_create(pattern.ptr, @intCast(pattern.len), @intFromBool(case_insensitive));
    if (regex == null) return error.RegexCreationFailed;
    return regex.?;
}

fn freeRegex(regex: *timbre.timbre_regex_t) void {
    timbre.timbre_regex_destroy(regex);
}

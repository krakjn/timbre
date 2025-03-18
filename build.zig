//  ______   __     __    __     ______     ______     ______
// /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\
// \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\
//    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\
//     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/

const std = @import("std");
const common = @import("zig/common.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const prefix = b.option([]const u8, "prefix", "Installation prefix") orelse "out";

    // Get build configuration based on target
    const target_triple = target.result.zigTriple(b.allocator) catch |err| {
        std.debug.print("Error getting target triple: {}\n", .{err});
        return;
    };

    const config = common.getBuildConfig(target_triple, optimize, prefix);

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "timbre",
        .target = target,
        .optimize = config.optimize,
    });

    exe.addCSourceFiles(.{
        .files = &.{
            "src/main.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
        },
        .flags = &.{
            "-std=c++17",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-pedantic",
        },
    });

    exe.addIncludePath(.{ .cwd_relative = "inc" });
    exe.linkLibCpp();

    b.installArtifact(exe);

    if (config.optimize == .ReleaseFast) {
        exe.addCSourceFiles(.{
            .files = &.{},
            .flags = &.{
                "-O3",
                "-DNDEBUG",
                "-flto",
                "-ffat-lto-objects",
                "-flto-partition=one",
                "-fno-rtti",
                "-funroll-loops",
                // "-march=native",
                // "-mtune=native",
            },
        });
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Create a "test" step
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "tests/test_timbre.cpp" },
        .target = target,
        .optimize = config.optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

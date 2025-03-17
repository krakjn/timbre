const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .musl,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const version_contents = fs.cwd().readFileAlloc(b.allocator, "pkg/version.txt", 1024) catch {
        print("Error: Could not read version.txt\n", .{});
        return;
    };
    defer b.allocator.free(version_contents);

    // Parse version
    var it = std.mem.splitScalar(u8, version_contents, '.');
    const major = it.next() orelse "0";
    const minor = it.next() orelse "0";
    const patch = it.next() orelse "0";

    const current_branch = std.mem.trim(u8, b.run(&[_][]const u8{
        "git",
        "rev-parse",
        "--abbrev-ref",
        "HEAD",
    }), "\n\r");
    const is_dev = !std.mem.eql(u8, current_branch, "main");
    const is_dev_str = if (is_dev) "1" else "0";
    const git_sha = std.mem.trim(u8, b.run(&[_][]const u8{
        "git",
        "rev-parse",
        "--short=8",
        "HEAD",
    }), "\n\r");

    const version_h_content = b.fmt(
        \\#pragma once
        \\
        \\#define TIMBRE_VERSION_MAJOR {s}
        \\#define TIMBRE_VERSION_MINOR {s}
        \\#define TIMBRE_VERSION_PATCH {s}
        \\#define TIMBRE_VERSION_SHA "{s}"
        \\#define TIMBRE_IS_DEV {s}
        \\
    , .{ major, minor, patch, git_sha, is_dev_str });

    fs.cwd().makePath("inc/timbre") catch {
        print("Error: Could not create inc/timbre directory\n", .{});
        return;
    };

    // Generate version.h
    fs.cwd().writeFile(.{
        .sub_path = "inc/timbre/version.h",
        .data = version_h_content,
    }) catch {
        print("Error: Could not write version.h\n", .{});
        return;
    };

    const exe = b.addExecutable(.{
        .name = "timbre",
        .target = target,
        .optimize = optimize,
    });

    // Add C source files with new API
    exe.addCSourceFiles(.{
        .files = &.{
            "src/main.cpp",
            "src/log.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
        },
        .flags = &[_][]const u8{
            "-std=c++17",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-pedantic",
        },
    });

    exe.addIncludePath(.{ .cwd_relative = "inc" });
    exe.linkLibCpp();

    if (optimize == .ReleaseFast) {
        exe.addCSourceFiles(.{
            .files = &.{},
            .flags = &[_][]const u8{
                "-O3",
                "-DNDEBUG",
                "-flto",
                "-ffat-lto-objects",
                "-flto-partition=one",
                "-funroll-loops",
            },
        });
    }

    b.installArtifact(exe);
}

//  ______   __     __    __     ______     ______     ______
// /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\
// \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\
//    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\
//     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the native build (default)
    const exe = b.addExecutable(.{
        .name = "timbre",
        .target = target,
        .optimize = optimize,
    });

    generateVersionFile(b);
    addSources(exe, optimize);
    b.installArtifact(exe);

    // Add run step for native build
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    addCrossTargets(b, optimize);
}

fn addSources(exe: *std.Build.Step.Compile, optimize: std.builtin.Mode) void {
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

    // Add release-specific flags if in release mode
    if (optimize == .ReleaseFast) {
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
            },
        });
    }
}

pub fn generateVersionFile(b: *std.Build) void {
    const version_contents = std.fs.cwd().readFileAlloc(b.allocator, "pkg/version.txt", 1024) catch {
        std.debug.print("Error: Could not read version.txt\n", .{});
        return;
    };
    defer b.allocator.free(version_contents);

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

    std.fs.cwd().makePath("inc/timbre") catch {
        std.debug.print("Error: Could not create inc/timbre directory\n", .{});
        return;
    };

    std.fs.cwd().writeFile(.{
        .sub_path = "inc/timbre/version.h",
        .data = version_h_content,
    }) catch {
        std.debug.print("Error: Could not write version.h\n", .{});
        return;
    };
}

fn addCrossTargets(b: *std.Build, optimize: std.builtin.Mode) void {
    const targets = [_][]const u8{
        "aarch64-macos-none",
        "x86_64-macos-none",
        "aarch64-linux-musl",
        "x86_64-linux-musl",
        "aarch64-windows-gnu",
        "x86_64-windows-gnu",
    };

    const all_step = b.step("all", "Build for all targets");

    // Create individual target steps
    for (targets) |triple| {
        const target_query = std.Target.Query.parse(.{
            .arch_os_abi = triple,
        }) catch |err| {
            std.debug.print("Error parsing target triple '{s}': {}\n", .{ triple, err });
            continue;
        };
        const resolved_target = b.resolveTargetQuery(target_query);

        const target_exe = b.addExecutable(.{
            .name = "timbre",
            .target = resolved_target,
            .optimize = optimize,
        });

        addSources(target_exe, optimize);

        const target_install = b.addInstallArtifact(target_exe, .{});
        target_install.dest_dir = .{ .custom = b.pathJoin(&.{ "out", triple }) };

        // Add a step for building this specific target
        const target_step = b.step(triple, b.fmt("Build for {s}", .{triple}));
        target_step.dependOn(&target_install.step);

        // Add this target to the "all" step
        all_step.dependOn(&target_install.step);
    }
}

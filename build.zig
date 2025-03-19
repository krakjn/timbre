//  ______   __     __    __     ______     ______     ______
// /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\
// \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\
//    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\
//     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/

const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_clang_tidy = b.option(bool, "clang-tidy", "Enable clang-tidy static analysis (checks: clang-analyzer-*, portability-*)") orelse false;
    const enable_cppcheck = b.option(bool, "cppcheck", "Enable cppcheck static analysis with third-party library exclusions") orelse false;

    const exe = b.addExecutable(.{
        .name = "timbre",
        .target = target,
        .optimize = optimize,
    });

    generateVersionFile(b);
    addSources(exe, optimize, enable_clang_tidy, enable_cppcheck);
    b.installArtifact(exe);

    // Add run step for native build
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    addDebianPackaging(b, exe, target);

    const test_step = b.step("test", "Run tests");

    const zig_tests = b.addTest(.{
        .root_source_file = b.path("tests/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    zig_tests.addIncludePath(.{ .cwd_relative = "tests" }); // Add tests directory to include path
    zig_tests.addIncludePath(.{ .cwd_relative = "inc" }); // Still need the main include directory

    zig_tests.addCSourceFiles(.{
        .files = &.{
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
        },
        .flags = &.{
            "-std=c++17",
            "-fPIC",
        },
    });

    zig_tests.addCSourceFiles(.{
        .files = &.{
            "tests/interface.c",
        },
        .flags = &.{
            "-std=c11",
            "-fPIC",
        },
    });

    zig_tests.linkLibCpp();

    const run_zig_tests = b.addRunArtifact(zig_tests);
    test_step.dependOn(&run_zig_tests.step);

    addCrossTargets(b, optimize);
}

fn addSources(exe: *std.Build.Step.Compile, optimize: std.builtin.Mode, enable_clang_tidy: bool, enable_cppcheck: bool) void {
    var flags = std.ArrayList([]const u8).init(exe.step.owner.allocator);
    defer flags.deinit();

    flags.appendSlice(&.{
        "-std=c++17",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-pedantic",
    }) catch unreachable;

    if (optimize == .ReleaseFast) {
        flags.appendSlice(&.{
            "-O3",
            "-DNDEBUG",
            "-flto",
            "-ffat-lto-objects",
            "-flto-partition=one",
            "-fno-rtti",
            "-funroll-loops",
        }) catch unreachable;
    }

    if (enable_clang_tidy) {
        const clang_tidy = exe.step.owner.addSystemCommand(&.{
            "clang-tidy",
            "src/main.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
            "--",
            "-I./inc",
            "-std=c++17",
        });
        clang_tidy.addArg("-checks=-*,clang-analyzer-*,portability-*");
        exe.step.dependOn(&clang_tidy.step);
    }

    if (enable_cppcheck) {
        const cppcheck = exe.step.owner.addSystemCommand(&.{
            "cppcheck",
            "--suppress=toomanyconfigs",
            "-I",
            "./inc/timbre",
            "--suppress=*:./inc/toml/*",
            "--suppress=*:./inc/CLI/*",
            "--suppress=*:./tests/*",
            "src/main.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
        });
        exe.step.dependOn(&cppcheck.step);
    }

    exe.addCSourceFiles(.{
        .files = &.{
            "src/main.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
        },
        .flags = flags.items,
    });

    exe.addIncludePath(.{ .cwd_relative = "inc" });
    exe.linkLibCpp();
}

fn addDebianPackaging(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    const package_step = b.step("package", "Create a Debian package (.deb) for distribution");

    const version = getVersionString(b);
    const arch = @tagName(target.result.cpu.arch);
    const deb_arch = blk: {
        if (std.mem.eql(u8, arch, "aarch64")) {
            break :blk "arm64";
        } else if (std.mem.eql(u8, arch, "x86_64")) {
            break :blk "amd64";
        } else {
            break :blk arch;
        }
    };

    const pkg_dir = b.fmt("build/pkg-{s}", .{deb_arch});
    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p" });
    mkdir_cmd.addArgs(&.{
        b.fmt("{s}/DEBIAN", .{pkg_dir}),
        b.fmt("{s}/usr/bin", .{pkg_dir}),
        b.fmt("{s}/usr/share/doc/timbre", .{pkg_dir}),
    });

    const control_content = b.fmt(
        \\Package: {s}
        \\Version: {s}
        \\Architecture: {s}
        \\Maintainer: {s}
        \\Depends: {s}
        \\Section: {s}
        \\Priority: {s}
        \\Homepage: {s}
        \\Description: {s}
        \\ {s}
        \\
    , .{
        "timbre",
        version,
        deb_arch,
        "Tony B <krakjn@gmail.com>",
        "libc6, libstdc++6",
        "utils",
        "optional",
        "https://github.com/krakjn/timbre",
        "A modern C++ logging utility",
        "A modern, efficient, and flexible logging utility for C++ applications. It provides a clean command-line interface for structured logging with support for multiple output formats and destinations.",
    });

    const write_control = b.addWriteFile(b.fmt("{s}/DEBIAN/control", .{pkg_dir}), control_content);

    const installed_exe = b.addInstallArtifact(exe, .{});

    const copy_exe = b.addSystemCommand(&.{ "cp", b.getInstallPath(.bin, "timbre"), b.fmt("{s}/usr/bin/", .{pkg_dir}) });
    copy_exe.step.dependOn(&installed_exe.step);

    const dpkg_cmd = b.addSystemCommand(&.{
        "dpkg-deb",
        "--build",
        "--root-owner-group",
        pkg_dir,
        b.fmt("build/timbre-{s}-{s}.deb", .{ version, deb_arch }),
    });

    dpkg_cmd.step.dependOn(&write_control.step);
    dpkg_cmd.step.dependOn(&mkdir_cmd.step);
    dpkg_cmd.step.dependOn(&copy_exe.step);

    package_step.dependOn(&dpkg_cmd.step);
}

fn getVersionString(b: *std.Build) []const u8 {
    const version_contents = std.fs.cwd().readFileAlloc(b.allocator, "pkg/version.txt", 1024) catch {
        return "0.0.0";
    };
    defer b.allocator.free(version_contents);

    return std.mem.trim(u8, version_contents, "\n\r");
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

    const all_step = b.step("all", "Build all cross-compilation targets (output to out/<triple>)");

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

        addSources(target_exe, optimize, false, false);

        const target_install = b.addInstallArtifact(target_exe, .{});
        target_install.dest_dir = .{ .custom = b.pathJoin(&.{ "out", triple }) };

        // Add a step for building this specific target
        const target_step = b.step(triple, b.fmt("Build for {s}", .{triple}));
        target_step.dependOn(&target_install.step);

        // Add this target to the "all" step
        all_step.dependOn(&target_install.step);
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

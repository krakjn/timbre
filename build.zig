//  ______   __     __    __     ______     ______     ______
// /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\
// \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\
//    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\
//     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/

const std = @import("std");
const builtin = @import("builtin");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

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

    const version = generateVersionFile(b);
    addSources(
        exe,
        enable_clang_tidy,
        enable_cppcheck,
        getFlags(.cpp, optimize, target.result.os.tag, target.result.cpu.arch),
    );
    b.installArtifact(exe);

    // Add run step for native build
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const all_step = b.step("all", "Build all cross-compilation targets");
    var target_steps = std.StringHashMap(*std.Build.Step).init(b.allocator);

    for (targets) |t| {
        const resolved_target = b.resolveTargetQuery(t);
        const triple = t.zigTriple(b.allocator) catch {
            std.debug.print("Error getting triple for target\n", .{});
            continue;
        };

        const target_exe = b.addExecutable(.{
            .name = "timbre",
            .target = resolved_target,
            .optimize = optimize,
        });

        const flags = getFlags(.cpp, optimize, resolved_target.result.os.tag, resolved_target.result.cpu.arch);
        addSources(target_exe, false, false, flags);

        const target_install = b.addInstallArtifact(target_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = triple,
                },
            },
        });

        // Add a step for building this specific target
        const target_step = b.step(triple, b.fmt("Build for {s}", .{triple}));
        target_step.dependOn(&target_install.step);

        // Store the step in the hash map
        target_steps.put(triple, target_step) catch {
            std.debug.print("Error storing step for triple '{s}'\n", .{triple});
        };

        // Add this target to the "all" step
        all_step.dependOn(&target_install.step);
    }

    // Add packaging step that depends on cross-compilation
    addDebianPackaging(b, target_steps, version);

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
        .flags = getFlags(.cpp, optimize, target.result.os.tag, target.result.cpu.arch),
    });

    zig_tests.addCSourceFiles(.{
        .files = &.{
            "tests/interface.c",
        },
        .flags = getFlags(.c, optimize, target.result.os.tag, target.result.cpu.arch),
    });

    zig_tests.linkLibCpp();

    const run_zig_tests = b.addRunArtifact(zig_tests);
    test_step.dependOn(&run_zig_tests.step);
}

const Language = enum {
    c,
    cpp,
};

fn getFlags(lang: Language, optimize: std.builtin.Mode, os_tag: std.Target.Os.Tag, arch: std.Target.Cpu.Arch) []const []const u8 {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();

    flags.appendSlice(&.{
        "-Wall",
        "-Wextra",
        "-Werror",
        "-pedantic",
        "-fPIC",
    }) catch unreachable;

    switch (lang) {
        .c => flags.appendSlice(&.{
            "-std=c11",
        }) catch unreachable,
        .cpp => flags.appendSlice(&.{
            "-std=c++17",
        }) catch unreachable,
    }

    if (optimize == .ReleaseFast) {
        flags.appendSlice(&.{
            "-DNDEBUG",
            "-O3",
            "-fno-rtti",
            "-funroll-loops",
        }) catch unreachable;

        switch (os_tag) {
            .windows => {
                // Windows: avoid LTO due to PDB generation issues
                flags.appendSlice(&.{
                    "-D_WIN32",
                    "-DWIN32_LEAN_AND_MEAN",
                }) catch unreachable;
            },
            .linux => {
                // Due to Clang/LLVM, thin LTO is best
                flags.appendSlice(&.{
                    "-flto=thin",
                }) catch unreachable;
            },
            // macOS: avoid LTO in cross-compilation to prevent TBD parsing errors
            else => {},
        }
    }

    // Architecture-specific flags
    switch (arch) {
        .x86_64 => {
            flags.appendSlice(&.{
                "-march=x86-64",
                "-mtune=generic",
            }) catch unreachable;

            // Add AVX2 for macOS and Windows x64
            // NOTE: AVX2 (Advanced Vector Extensions 2) is a CPU instruction set extension
            // that enables advanced SIMD (Single Instruction, Multiple Data) operations.
            if (os_tag == .macos or os_tag == .windows) {
                flags.appendSlice(&.{
                    "-mavx2",
                }) catch unreachable;
            }
        },
        .aarch64 => {
            if (os_tag == .macos) {
                // Use Apple Silicon optimizations
                flags.appendSlice(&.{
                    "-march=armv8.5-a",
                    "-mcpu=apple-m1",
                }) catch unreachable;
            } else {
                // Generic ARM64
                flags.appendSlice(&.{
                    "-march=armv8-a",
                }) catch unreachable;
            }
        },
        else => {},
    }

    return flags.toOwnedSlice() catch unreachable;
}

fn addSources(exe: *std.Build.Step.Compile, enable_clang_tidy: bool, enable_cppcheck: bool, platform_flags: []const []const u8) void {
    var flags = std.ArrayList([]const u8).init(exe.step.owner.allocator);
    defer flags.deinit();

    flags.appendSlice(platform_flags) catch unreachable;

    if (enable_clang_tidy) {
        const clang_tidy = exe.step.owner.addSystemCommand(&.{
            "clang-tidy",
            "src/main.cpp",
            "src/timbre.cpp",
            "src/config.cpp",
            "src/log.cpp",
            "--checks=-*,clang-analyzer-*,portability-*",
            "--",
            "-I./inc",
            "-std=c++17",
        });
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

fn addDebianPackaging(b: *std.Build, target_steps: std.StringHashMap(*std.Build.Step), version: []const u8) void {
    const package_step = b.step("package", "Create a Debian package (.deb) for distribution");

    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/pkg" });

    // NOTE: this is to ensure the cross-compilation targets are built first
    const amd64_step = target_steps.get("x86_64-linux-musl") orelse {
        std.debug.print("Error: x86_64-linux-musl target not found\n", .{});
        return;
    };

    const arm64_step = target_steps.get("aarch64-linux-musl") orelse {
        std.debug.print("Error: aarch64-linux-musl target not found\n", .{});
        return;
    };

    const amd64_pkg = b.addSystemCommand(&.{
        "bash", "pkg/build_deb.sh", "amd64", version,
    });
    amd64_pkg.step.dependOn(&mkdir_cmd.step);
    amd64_pkg.step.dependOn(amd64_step);

    const arm64_pkg = b.addSystemCommand(&.{
        "bash", "pkg/build_deb.sh", "arm64", version,
    });
    arm64_pkg.step.dependOn(&mkdir_cmd.step);
    arm64_pkg.step.dependOn(arm64_step);

    package_step.dependOn(&amd64_pkg.step);
    package_step.dependOn(&arm64_pkg.step);
}

pub fn generateVersionFile(b: *std.Build) []const u8 {
    const version_contents = std.fs.cwd().readFileAlloc(b.allocator, "pkg/version.txt", 1024) catch {
        std.debug.print("Error: Could not read version.txt\n", .{});
        return "0.0.0";
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

    std.fs.cwd().writeFile(.{
        .sub_path = "inc/timbre/version.h",
        .data = version_h_content,
    }) catch {
        std.debug.print("Error: Could not write version.h\n", .{});
        return "0.0.0";
    };

    return if (is_dev)
        // NOTE: debpkg-deb does not like `_` or `-` in the version string
        std.fmt.allocPrint(b.allocator, "{s}+{s}", .{ strip(version_contents), git_sha }) catch unreachable
    else
        std.fmt.allocPrint(b.allocator, "{s}", .{strip(version_contents)}) catch unreachable;
}

fn strip(str: []const u8) []const u8 {
    return std.mem.trim(u8, str, "\n\r");
}

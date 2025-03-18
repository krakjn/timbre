const std = @import("std");

pub const BuildConfig = struct {
    target: std.Target,
    optimize: std.builtin.Mode,
    prefix: []const u8,
    name: []const u8,
};

// Static buffer for storing the parsed triple
var triple_buf: [64]u8 = undefined;

fn parseTriple(target_name: []const u8) []const u8 {
    var parts = std.mem.splitScalar(u8, target_name, '-');
    const arch = parts.next() orelse return target_name;
    const os_with_ver = parts.next() orelse return target_name;
    const abi_with_ver = parts.next() orelse return target_name;

    // Handle version numbers in OS and ABI
    var os_parts = std.mem.splitScalar(u8, os_with_ver, '.');
    var abi_parts = std.mem.splitScalar(u8, abi_with_ver, '.');

    const os = os_parts.next() orelse os_with_ver;
    const abi = abi_parts.next() orelse abi_with_ver;

    // For Linux targets, always use musl ABI
    if (std.mem.eql(u8, os, "linux")) {
        return std.fmt.bufPrint(&triple_buf, "{s}-{s}-musl", .{
            arch,
            os,
        }) catch return target_name;
    }

    // For macOS targets, omit the ABI
    if (std.mem.eql(u8, os, "macos")) {
        return std.fmt.bufPrint(&triple_buf, "{s}-{s}", .{
            arch,
            os,
        }) catch return target_name;
    }

    // For Windows targets, use MSVC ABI
    if (std.mem.eql(u8, os, "windows")) {
        return std.fmt.bufPrint(&triple_buf, "{s}-{s}-msvc", .{
            arch,
            os,
        }) catch return target_name;
    }

    return std.fmt.bufPrint(&triple_buf, "{s}-{s}-{s}", .{
        arch,
        os,
        abi,
    }) catch return target_name;
}

pub fn is_supported(target_name: []const u8, valid_targets: []const []const u8) bool {
    const base_triple = parseTriple(target_name);
    std.debug.print("Parsed triple: {s}\n", .{base_triple});

    for (valid_targets) |valid_target| {
        if (std.mem.eql(u8, base_triple, valid_target)) {
            return true;
        }
    }
    return false;
}

pub fn getBuildConfig(
    target_name: []const u8,
    optimize: std.builtin.Mode,
    prefix: []const u8,
) BuildConfig {
    const base_triple = parseTriple(target_name);
    std.debug.print("Building: {s}\n", .{base_triple});

    const target = if (std.mem.eql(u8, base_triple, "aarch64-macos"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .macos,
            .abi = .none,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.apple_m1 },
            .cpu_features_add = std.Target.aarch64.featureSet(&.{.v8a}),
        }) catch @panic("Failed to resolve target")
    else if (std.mem.eql(u8, base_triple, "x86_64-macos"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .macos,
            .abi = .none,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.skylake },
        }) catch @panic("Failed to resolve target")
    else if (std.mem.eql(u8, base_triple, "aarch64-linux-musl"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .musl,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.generic },
            .cpu_features_add = std.Target.aarch64.featureSet(&.{.v8a}),
        }) catch @panic("Failed to resolve target")
    else if (std.mem.eql(u8, base_triple, "x86_64-linux-musl"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .musl,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.skylake },
        }) catch @panic("Failed to resolve target")
    else if (std.mem.eql(u8, base_triple, "aarch64-windows-msvc"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .windows,
            .abi = .msvc,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.generic },
            .cpu_features_add = std.Target.aarch64.featureSet(&.{.v8a}),
        }) catch @panic("Failed to resolve target")
    else if (std.mem.eql(u8, base_triple, "x86_64-windows-msvc"))
        std.zig.system.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.skylake },
        }) catch @panic("Failed to resolve target")
    else {
        std.debug.print("Unsupported target: {s}\n", .{base_triple});
        @panic("Unknown target");
    };

    return .{
        .target = target,
        .optimize = optimize,
        .prefix = prefix,
        .name = target_name,
    };
}

const std = @import("std");
const Builder = std.build.Builder;
const Build = std.build;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vcpkg = b.option(bool, "vcpkg", "Add vcpkg paths to the build") orelse false;

    var exe = b.addExecutable(.{
        .name = "tetris",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    exe.addCSourceFile("stb_image-2.22/stb_image_impl.c", &[_][]const u8{"-std=c99"});

    if (vcpkg) {
        exe.addVcpkgPaths(.static) catch @panic("Cannot add vcpkg paths.");
    }

    exe.addIncludePath("stb_image-2.22");

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    exe.install();

    const play = b.step("play", "Play the game");
    const run = exe.run();
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

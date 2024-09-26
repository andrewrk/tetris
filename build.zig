const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_llvm = b.option(bool, "use-llvm", "use the LLVM backend");

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe = b.addExecutable(.{
        .name = "tetris",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
        .use_llvm = use_llvm,
        .use_lld = use_llvm,
    });
    const c_module = translate_c.createModule();
    c_module.linkSystemLibrary("glfw", .{});
    c_module.linkSystemLibrary("epoxy", .{});
    exe.root_module.addImport("c", c_module);

    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

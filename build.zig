const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_llvm = b.option(bool, "use-llvm", "use the LLVM backend");

    const exe = b.addExecutable(.{
        .name = "tetris",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
        .use_llvm = use_llvm,
        .use_lld = use_llvm,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});

    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });
    translator.linkSystemLibrary("glfw3", .{});
    translator.linkSystemLibrary("epoxy", .{});

    const exe = b.addExecutable(.{
        .name = "tetris",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target,
            .imports = &.{
                .{
                    .name = "c",
                    .module = translator.mod,
                },
            },
        }),
    });

    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

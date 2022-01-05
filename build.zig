const std = @import("std");
const Builder = std.build.Builder;
const Linkage = std.build.LibExeObjStep.Linkage;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const windows = b.option(bool, "windows", "create windows build") orelse false;
    const vcpkg = b.option(bool, "vcpkg", "Add vcpkg paths to the build") orelse false;

    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.addCSourceFile("stb_image-2.22/stb_image_impl.c", &[_][]const u8{"-std=c99"});
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(.{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .gnu,
        });
    }

    if (vcpkg) {
        const linkage: Linkage = if (windows) .dynamic else .static;
        exe.addVcpkgPaths(linkage) catch @panic("Cannot add vcpkg paths.");
    }

    exe.addIncludeDir("stb_image-2.22");

    exe.linkSystemLibrary("c");
    const glfwLibName = if (windows) "glfw3dll" else "glfw";
    exe.linkSystemLibrary(glfwLibName);
    exe.linkSystemLibrary("epoxy");
    exe.install();

    const play = b.step("play", "Play the game");
    const run = exe.run();
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

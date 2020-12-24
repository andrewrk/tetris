const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

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

        exe.linkSystemLibrary("glfw3dll");
    } else {
        exe.linkSystemLibrary("glfw");
    }

    if (vcpkg) {
        exe.addVcpkgPaths(builtin.LinkMode.Dynamic) catch @panic("Cannot add vcpkg paths.");
    }

    exe.addIncludeDir("stb_image-2.22");

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("epoxy");
    exe.install();

    const play = b.step("play", "Play the game");
    const run = exe.run();
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

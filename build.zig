const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const release = b.option(bool, "release", "optimizations on and safety off") ?? false;

    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.setRelease(release);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    exe.linkSystemLibrary("png");
    exe.linkSystemLibrary("z");

    b.default_step.dependOn(&exe.step);
}

const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    var exe = b.addExe("src/main.zig", "tetris");

    exe.linkLibrary("c");
    exe.linkLibrary("m");
    exe.linkLibrary("glfw");
    exe.linkLibrary("epoxy");
    exe.linkLibrary("png");
    exe.linkLibrary("z");
}

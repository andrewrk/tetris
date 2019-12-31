const c = @import("c.zig");
const std = @import("std");
const os = std.os;
const panic = std.debug.panic;
const builtin = @import("builtin");

pub const is_on = if (builtin.mode == builtin.Mode.ReleaseFast) c.GL_FALSE else c.GL_TRUE;

pub fn assertNoError() void {
    if (builtin.mode != builtin.Mode.ReleaseFast) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            panic("GL error: {}\n", .{err});
        }
    }
}

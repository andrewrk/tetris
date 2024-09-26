const c = @import("c.zig").c;
const std = @import("std");
const os = std.os;
const builtin = @import("builtin");

pub const is_on = if (builtin.mode == .ReleaseFast) c.GL_FALSE else c.GL_TRUE;

pub fn assertNoError() void {
    if (builtin.mode != .ReleaseFast) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            _ = c.printf("GL error: %d\n", err);
            c.abort();
        }
    }
}

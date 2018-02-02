const c = @import("c.zig");
const os = @import("std").os;
const builtin = @import("builtin");

pub const is_on = if (builtin.mode == builtin.Mode.ReleaseFast) c.GL_FALSE else c.GL_TRUE;

pub fn assertNoError() void {
    if (builtin.mode != builtin.Mode.ReleaseFast) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            _ = c.printf(c"GL error: %d\n", err);
            os.abort();
        }
    }
}

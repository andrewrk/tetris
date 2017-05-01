const c = @import("c.zig");
const os = @import("std").os;
const builtin = @import("builtin");

pub const is_on = if (builtin.is_release) c.GL_FALSE else c.GL_TRUE;

pub fn assertNoError() {
    if (!builtin.is_release) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            _ = c.printf(c"GL error: %d\n", err);
            os.abort();
        }
    }
}

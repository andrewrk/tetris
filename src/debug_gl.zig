const c = @import("c.zig");

pub const is_on = if (@compile_var("is_release")) c.GL_FALSE else c.GL_TRUE;

pub fn assert_no_error() {
    if (!@compile_var("is_release")) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            c.printf(c"GL error: %d\n", err);
            c.abort();
        }
    }
}

const c = @import("c.zig");

pub const is_on = if (@compileVar("is_release")) c.GL_FALSE else c.GL_TRUE;

pub fn assertNoError() {
    if (!@compileVar("is_release")) {
        const err = c.glGetError();
        if (err != c.GL_NO_ERROR) {
            _ = c.printf(c"GL error: %d\n", err);
            c.abort();
        }
    }
}

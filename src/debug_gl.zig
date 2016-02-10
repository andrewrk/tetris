import "libc.zig";

pub const gl_debug_on = if (@compile_var("is_release")) GL_FALSE else GL_TRUE;

pub fn assert_no_gl_error() {
    if (!@compile_var("is_release")) {
        const err = glGetError();
        if (err != GL_NO_ERROR) {
            fprintf(stderr, c"GL error: %d\n", err);
            abort();
        }
    }
}

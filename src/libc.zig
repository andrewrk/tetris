pub use @c_import({
    @c_include("epoxy/gl.h");
    @c_include("GLFW/glfw3.h");
    @c_include("png.h");
    @c_include("math.h");
    @c_include("stdlib.h");
    @c_include("stdio.h");
});

error NoMem;

pub fn mem_alloc(T: type)(n: isize) -> %[]T {
    return (&T)(malloc(size_t(n * @sizeof(T))) ?? return error.NoMem)[0...n];
}

pub fn mem_free(T: type)(mem: []T) {
    free((&c_void)(&mem[0]));
}

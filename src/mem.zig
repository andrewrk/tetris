const c = @import("libc.zig");
const size_t = c.size_t;

error NoMem;

pub fn alloc(T: type)(n: isize) -> %[]T {
    // TODO c.size_t() instead of import alias
    return (&T)(c.malloc(size_t(n * @sizeof(T))) ?? return error.NoMem)[0...n];
}

pub fn free(T: type)(mem: []T) {
    const x = (&c_void)(&mem[0]);
    c.free(x);
    //c.free((&c_void)(&mem[0]));
}

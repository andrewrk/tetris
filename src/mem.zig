const c = @import("c.zig");

error NoMem;

pub fn alloc(inline T: type, n: isize) -> %[]T {
    return (&T)(c.malloc(c.size_t(n * @sizeof(T))) ?? return error.NoMem)[0...n];
}

pub fn free(inline T: type, mem: []T) {
    c.free((&c_void)(&mem[0]));
}

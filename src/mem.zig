const c = @import("c.zig");

error NoMem;

pub fn alloc(comptime T: type, n: usize) -> %[]T {
    const the_mem = c.malloc(n * @sizeOf(T)) ?? return error.NoMem;
    const aligned = @alignCast(8, the_mem);
    return @ptrCast(&T, aligned)[0..n];
}

pub fn free(comptime T: type, mem: []T) {
    c.free(@ptrCast(&c_void, &mem[0]));
}

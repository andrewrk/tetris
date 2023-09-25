const std = @import("std");
const c = @import("c.zig");
const Bmp = @This();
const assert = std.debug.assert;

width: u32,
height: u32,
pitch: u32,
raw: []const u8,

const Header = extern struct {
    magic: [2]u8,
    size: u32 align(1),
    reserved: u32 align(1),
    pixel_offset: u32 align(1),
    header_size: u32 align(1),
    width: u32 align(1),
    height: u32 align(1),
};

pub fn create(compressed_bytes: []const u8) Bmp {
    const header: *const Header = @ptrCast(compressed_bytes);
    assert(header.magic[0] == 'B');
    assert(header.magic[1] == 'M');

    const bits_per_channel = 8;
    const channel_count = 4;
    const width = header.width;
    const height = header.height;
    const pitch = width * bits_per_channel * channel_count / 8;
    return .{
        .raw = compressed_bytes[header.pixel_offset..][0 .. height * pitch],
        .width = width,
        .height = height,
        .pitch = pitch,
    };
}

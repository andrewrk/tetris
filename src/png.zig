const c = @import("c.zig");

pub const PngImage = struct {
    width: u32,
    height: u32,
    pitch: u32,
    raw: []u8,

    pub fn destroy(pi: *PngImage) void {
        c.stbi_image_free(pi.raw.ptr);
    }

    pub fn create(compressed_bytes: []const u8) !PngImage {
        var pi: PngImage = undefined;

        var width: c_int = undefined;
        var height: c_int = undefined;

        if (c.stbi_info_from_memory(compressed_bytes.ptr, @intCast(c_int, compressed_bytes.len), &width, &height, null) == 0) {
            return error.NotPngFile;
        }

        if (width <= 0 or height <= 0) return error.NoPixels;
        pi.width = @intCast(u32, width);
        pi.height = @intCast(u32, height);

        // Not validating channel_count because it gets auto-converted to 4

        if (c.stbi_is_16_bit_from_memory(compressed_bytes.ptr, @intCast(c_int, compressed_bytes.len)) != 0) {
            return error.InvalidFormat;
        }
        const bits_per_channel = 8;
        const channel_count = 4;

        c.stbi_set_flip_vertically_on_load(1);
        const image_data = c.stbi_load_from_memory(compressed_bytes.ptr, @intCast(c_int, compressed_bytes.len), &width, &height, null, channel_count);

        if (image_data == null) return error.NoMem;

        pi.pitch = pi.width * bits_per_channel * channel_count / 8;
        pi.raw = image_data[0 .. pi.height * pi.pitch];

        return pi;
    }
};

use @import("libc.zig");

pub struct PngImage {
    width: i32,
    height: i32,
    pitch: i32,
    raw: []u8,

    pub fn destroy(pi: &PngImage) {
        free((&c_void)(&pi.raw[0]));
    }
}

pub error NotPngFile;
pub error NoMem;
pub error InvalidFormat;
pub error NoPixels;

pub fn create_png_image(compressed_bytes: []u8) -> %PngImage {
    var pi : PngImage = undefined;

    if (png_sig_cmp(&compressed_bytes[0], 0, 8) != 0) {
        return error.NotPngFile;
    }

    const png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, null, null, null);
    png_ptr ?? return error.NoMem;

    const info_ptr = png_create_info_struct(png_ptr);
    info_ptr ?? {
        png_destroy_read_struct(&png_ptr, null, null);
        return error.NoMem;
    };
    defer png_destroy_read_struct(&png_ptr, &info_ptr, null);

    //// don't call any png_* functions outside of this function.
    //// cursed is he who thought setjmp and longjmp was in any way acceptable to
    //// bake into a library API.
    //if (setjmp((?&struct___jmp_buf_tag)(png_set_longjmp_fn(png_ptr, longjmp, @sizeof(jmp_buf)))) != 0) {
    //    return error.InvalidFormat;
    //}

    png_set_sig_bytes(png_ptr, 8);

    var png_io = PngIo {
        .index = 8,
        .buffer = compressed_bytes,
    };
    png_set_read_fn(png_ptr, (&c_void)(&png_io), tetris_read_png_data);

    png_read_info(png_ptr, info_ptr);

    pi.width  = i32(png_get_image_width(png_ptr, info_ptr));
    pi.height = i32(png_get_image_height(png_ptr, info_ptr));

    if (pi.width <= 0 || pi.height <= 0) return error.NoPixels;

    // bits per channel (not per pixel)
    const bits_per_channel = i32(png_get_bit_depth(png_ptr, info_ptr));
    if (bits_per_channel != 8) return error.InvalidFormat;

    const channel_count = i32(png_get_channels(png_ptr, info_ptr));
    if (channel_count != 4) return error.InvalidFormat;

    const color_type = png_get_color_type(png_ptr, info_ptr);
    if (color_type != PNG_COLOR_TYPE_RGBA) return error.InvalidFormat;

    pi.pitch = pi.width * bits_per_channel * channel_count / 8;
    // TODO generics so we can have a nice malloc wrapper
    const alloc_amt = pi.height * pi.pitch;
    pi.raw = (&u8)(malloc(size_t(alloc_amt)) ?? return error.NoMem)[0...alloc_amt];
    %defer free((&c_void)(&pi.raw[0]));

    const row_ptrs = (&png_bytep)(malloc(@sizeof(png_bytep) * size_t(pi.height)) ?? return error.NoMem);
    defer free((&c_void)(row_ptrs));

    // TODO for range
    var i: i32 = 0;
    while (i < pi.height) {
        const q = (pi.height - i - 1) * pi.pitch;
        row_ptrs[i] = &pi.raw[q];
        i += 1;
    }

    png_read_image(png_ptr, row_ptrs);

    return pi;
}

struct PngIo {
    index: isize,
    buffer: []u8,
}

// TODO ability to make this extern instead of export
export fn tetris_read_png_data(png_ptr: png_structp, data: png_bytep, length: png_size_t) {
    const png_io = (&PngIo)(??png_get_io_ptr(png_ptr));
    const new_index = png_io.index + isize(length);
    if (new_index > png_io.buffer.len) unreachable{};
    @memcpy((&c_void)(??data), &png_io.buffer[png_io.index], isize(length));
    png_io.index = new_index;
}

const PNG_COLOR_TYPE_RGBA = PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA;

const std = @import("std");
const c = @import("c.zig");
const AllShaders = @import("all_shaders.zig").AllShaders;
const Mat4x4 = @import("math3d.zig").Mat4x4;
const PngImage = @import("png.zig").PngImage;

pub const Spritesheet = struct {
    img: PngImage,
    count: usize,
    texture_id: c.GLuint,
    vertex_buffer: c.GLuint,
    tex_coord_buffers: []c.GLuint,

    pub fn draw(s: *Spritesheet, as: AllShaders, index: usize, mvp: Mat4x4) void {
        as.texture.bind();
        as.texture.setUniformMat4x4(as.texture_uniform_mvp, mvp);
        as.texture.setUniformInt(as.texture_uniform_tex, 0);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, s.vertex_buffer);
        c.glEnableVertexAttribArray(@intCast(c.GLuint, as.texture_attrib_position));
        c.glVertexAttribPointer(@intCast(c.GLuint, as.texture_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, s.tex_coord_buffers[index]);
        c.glEnableVertexAttribArray(@intCast(c.GLuint, as.texture_attrib_tex_coord));
        c.glVertexAttribPointer(@intCast(c.GLuint, as.texture_attrib_tex_coord), 2, c.GL_FLOAT, c.GL_FALSE, 0, null);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, s.texture_id);

        c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
    }

    pub fn init(s: *Spritesheet, compressed_bytes: []const u8, w: usize, h: usize) !void {
        s.img = try PngImage.create(compressed_bytes);
        const col_count = s.img.width / w;
        const row_count = s.img.height / h;
        s.count = col_count * row_count;

        c.glGenTextures(1, &s.texture_id);
        errdefer c.glDeleteTextures(1, &s.texture_id);

        c.glBindTexture(c.GL_TEXTURE_2D, s.texture_id);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        c.glPixelStorei(c.GL_PACK_ALIGNMENT, 4);
        c.glTexImage2D(
            c.GL_TEXTURE_2D,
            0,
            c.GL_RGBA,
            @intCast(c_int, s.img.width),
            @intCast(c_int, s.img.height),
            0,
            c.GL_RGBA,
            c.GL_UNSIGNED_BYTE,
            @ptrCast(*anyopaque, &s.img.raw[0]),
        );

        c.glGenBuffers(1, &s.vertex_buffer);
        errdefer c.glDeleteBuffers(1, &s.vertex_buffer);

        const vertexes = [_][3]c.GLfloat{
            [_]c.GLfloat{ 0.0, 0.0, 0.0 },
            [_]c.GLfloat{ 0.0, @intToFloat(c.GLfloat, h), 0.0 },
            [_]c.GLfloat{ @intToFloat(c.GLfloat, w), 0.0, 0.0 },
            [_]c.GLfloat{ @intToFloat(c.GLfloat, w), @intToFloat(c.GLfloat, h), 0.0 },
        };

        c.glBindBuffer(c.GL_ARRAY_BUFFER, s.vertex_buffer);
        c.glBufferData(c.GL_ARRAY_BUFFER, 4 * 3 * @sizeOf(c.GLfloat), @ptrCast(*const anyopaque, &vertexes[0][0]), c.GL_STATIC_DRAW);

        s.tex_coord_buffers = try alloc(c.GLuint, s.count);
        //s.tex_coord_buffers = try c_allocator.alloc(c.GLuint, s.count);
        //errdefer c_allocator.free(s.tex_coord_buffers);

        c.glGenBuffers(@intCast(c.GLint, s.tex_coord_buffers.len), s.tex_coord_buffers.ptr);
        errdefer c.glDeleteBuffers(@intCast(c.GLint, s.tex_coord_buffers.len), &s.tex_coord_buffers[0]);

        for (s.tex_coord_buffers) |tex_coord_buffer, i| {
            const upside_down_row = i / col_count;
            const col = i % col_count;
            const row = row_count - upside_down_row - 1;

            const x = @intToFloat(f32, col * w);
            const y = @intToFloat(f32, row * h);

            const img_w = @intToFloat(f32, s.img.width);
            const img_h = @intToFloat(f32, s.img.height);
            const tex_coords = [_][2]c.GLfloat{
                [_]c.GLfloat{
                    x / img_w,
                    (y + @intToFloat(f32, h)) / img_h,
                },
                [_]c.GLfloat{
                    x / img_w,
                    y / img_h,
                },
                [_]c.GLfloat{
                    (x + @intToFloat(f32, w)) / img_w,
                    (y + @intToFloat(f32, h)) / img_h,
                },
                [_]c.GLfloat{
                    (x + @intToFloat(f32, w)) / img_w,
                    y / img_h,
                },
            };

            c.glBindBuffer(c.GL_ARRAY_BUFFER, tex_coord_buffer);
            c.glBufferData(c.GL_ARRAY_BUFFER, 4 * 2 * @sizeOf(c.GLfloat), @ptrCast(*const anyopaque, &tex_coords[0][0]), c.GL_STATIC_DRAW);
        }
    }

    pub fn deinit(s: *Spritesheet) void {
        c.glDeleteBuffers(@intCast(c.GLint, s.tex_coord_buffers.len), s.tex_coord_buffers.ptr);
        //c_allocator.free(s.tex_coord_buffers);
        c.glDeleteBuffers(1, &s.vertex_buffer);
        c.glDeleteTextures(1, &s.texture_id);

        s.img.destroy();
    }
};

fn alloc(comptime T: type, n: usize) ![]T {
    const ptr = c.malloc(@sizeOf(T) * n) orelse return error.OutOfMemory;
    return @ptrCast([*]T, @alignCast(@alignOf(T), ptr))[0..n];
}

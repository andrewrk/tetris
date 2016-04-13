use @import("libc.zig");
use @import("png.zig");
use @import("all_shaders.zig");
use @import("math3d.zig");
const mem = @import("mem.zig");

pub struct Spritesheet {
    img: PngImage,
    count: i32,
    texture_id: GLuint,
    vertex_buffer: GLuint,
    tex_coord_buffers: []GLuint,

    pub fn draw(s: &Spritesheet, shaders: AllShaders, index: i32, mvp: Mat4x4) {
        shaders.texture.bind();
        shaders.texture.set_uniform_mat4x4(shaders.texture_uniform_mvp, mvp);
        shaders.texture.set_uniform_int(shaders.texture_uniform_tex, 0);

        glBindBuffer(GL_ARRAY_BUFFER, s.vertex_buffer);
        glEnableVertexAttribArray(GLuint(shaders.texture_attrib_position));
        glVertexAttribPointer(GLuint(shaders.texture_attrib_position), 3, GL_FLOAT, GL_FALSE, 0, null);

        glBindBuffer(GL_ARRAY_BUFFER, s.tex_coord_buffers[index]);
        glEnableVertexAttribArray(GLuint(shaders.texture_attrib_tex_coord));
        glVertexAttribPointer(GLuint(shaders.texture_attrib_tex_coord), 2, GL_FLOAT, GL_FALSE, 0, null);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, s.texture_id);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    pub fn deinit(s: &Spritesheet) {
        glDeleteBuffers(GLint(s.tex_coord_buffers.len), &s.tex_coord_buffers[0]);
        mem.free(GLuint)(s.tex_coord_buffers);
        glDeleteBuffers(1, &s.vertex_buffer);
        glDeleteTextures(1, &s.texture_id);

        s.img.destroy();
    }
}

pub error NoMem;

pub fn spritesheet_init(filename: &const u8, w: i32, h: i32) -> %Spritesheet {
    var s: Spritesheet = undefined;

    var buffer: [10 * 1024]u8 = undefined;
    const compressed_bytes = %return fs_fetch_file(filename, buffer);

    s.img = %return create_png_image(compressed_bytes);
    const col_count = s.img.width / w;
    const row_count = s.img.height / h;
    s.count = col_count * row_count;

    glGenTextures(1, &s.texture_id);
    %defer glDeleteTextures(1, &s.texture_id);

    glBindTexture(GL_TEXTURE_2D, s.texture_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
            s.img.width, s.img.height,
            0, GL_RGBA, GL_UNSIGNED_BYTE, (&c_void)(&s.img.raw[0]));

    glGenBuffers(1, &s.vertex_buffer);
    %defer glDeleteBuffers(1, &s.vertex_buffer);

    const vertexes = [][3]GLfloat {
        []GLfloat{0.0,        0.0,        0.0},
        []GLfloat{0.0,        GLfloat(h), 0.0},
        []GLfloat{GLfloat(w), 0.0,        0.0},
        []GLfloat{GLfloat(w), GLfloat(h), 0.0},
    };

    glBindBuffer(GL_ARRAY_BUFFER, s.vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, 4 * 3 * @sizeof(GLfloat), (&c_void)(&vertexes[0][0]), GL_STATIC_DRAW);


    s.tex_coord_buffers = mem.alloc(GLuint)(s.count) %% return error.NoMem;
    %defer mem.free(GLuint)(s.tex_coord_buffers);

    glGenBuffers(GLint(s.tex_coord_buffers.len), &s.tex_coord_buffers[0]);
    %defer glDeleteBuffers(GLint(s.tex_coord_buffers.len), &s.tex_coord_buffers[0]);

    for (s.tex_coord_buffers) |tex_coord_buffer, i| {
        const upside_down_row = i / col_count;
        const col = i % col_count;
        const row = row_count - upside_down_row - 1;

        const x = f32(col * w);
        const y = f32(row * h);

        const img_w = f32(s.img.width);
        const img_h = f32(s.img.height);
        const tex_coords = [][2]GLfloat {
            []GLfloat{
                x / img_w,
                (y + f32(h)) / img_h,
            },
            []GLfloat{
                x / img_w,
                y / img_h,
            },
            []GLfloat{
                (x + f32(w)) / img_w,
                (y + f32(h)) / img_h,
            },
            []GLfloat{
                (x + f32(w)) / img_w,
                y / img_h,
            },
        };

        glBindBuffer(GL_ARRAY_BUFFER, tex_coord_buffer);
        glBufferData(GL_ARRAY_BUFFER, 4 * 2 * @sizeof(GLfloat), (&c_void)(&tex_coords[0][0]), GL_STATIC_DRAW);
    }

    return s;
}

// TODO implement in zig standard library and use that instead of relying on libc
error OpenFail;
error ReadFail;
fn fs_fetch_file(path: &const u8, buffer: []u8) -> %[]u8 {
    const file = fopen(path, c"rb") ?? return error.OpenFail;
    const amt_read = fread((&c_void)(&buffer[0]), 1, size_t(buffer.len), file);
    if (amt_read < 0) return error.ReadFail;
    fclose(file);
    return buffer[0...isize(amt_read)];
}

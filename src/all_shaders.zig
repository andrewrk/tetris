const os = @import("std").os;
const c = @import("c.zig");
const math3d = @import("math3d.zig");
const debug_gl = @import("debug_gl.zig");
const mem = @import("mem.zig");
const Vec4 = math3d.Vec4;
const Mat4x4 = math3d.Mat4x4;

pub const AllShaders = struct {
    primitive: ShaderProgram,
    primitive_attrib_position: c.GLint,
    primitive_uniform_mvp: c.GLint,
    primitive_uniform_color: c.GLint,

    texture: ShaderProgram,
    texture_attrib_tex_coord: c.GLint,
    texture_attrib_position: c.GLint,
    texture_uniform_mvp: c.GLint,
    texture_uniform_tex: c.GLint,

    pub fn destroy(as: &AllShaders) {
        as.primitive.destroy();
        as.texture.destroy();
    }
};

pub const ShaderProgram = struct {
    program_id: c.GLuint,
    vertex_id: c.GLuint,
    fragment_id: c.GLuint,
    geometry_id: ?c.GLuint,
    

    pub fn bind(sp: &const ShaderProgram) {
        c.glUseProgram(sp.program_id);
    }

    pub fn attrib_location(sp: &const ShaderProgram, name: &const u8) -> c.GLint {
        const id = c.glGetAttribLocation(sp.program_id, name);
        if (id == -1) {
            _ = c.printf(c"invalid attrib: %s\n", name);
            os.abort();
        }
        return id;
    }

    pub fn uniform_location(sp: &const ShaderProgram, name: &const u8) -> c.GLint {
        const id = c.glGetUniformLocation(sp.program_id, name);
        if (id == -1) {
            _ = c.printf(c"invalid uniform: %s\n", name);
            os.abort();
        }
        return id;
    }

    pub fn set_uniform_int(sp: &const ShaderProgram, uniform_id: c.GLint, value: c_int) {
        c.glUniform1i(uniform_id, value);
    }

    pub fn set_uniform_float(sp: &const ShaderProgram, uniform_id: c.GLint, value: f32) {
        c.glUniform1f(uniform_id, value);
    }

    pub fn set_uniform_vec3(sp: &const ShaderProgram, uniform_id: c.GLint, value: &const math3d.Vec3) {
        c.glUniform3fv(uniform_id, 1, &value.data[0]);
    }

    pub fn set_uniform_vec4(sp: &const ShaderProgram, uniform_id: c.GLint, value: &const Vec4) {
        c.glUniform4fv(uniform_id, 1, &value.data[0]);
    }

    pub fn set_uniform_mat4x4(sp: &const ShaderProgram, uniform_id: c.GLint, value: &const Mat4x4) {
        c.glUniformMatrix4fv(uniform_id, 1, c.GL_FALSE, &value.data[0][0]);
    }

    pub fn destroy(sp: &ShaderProgram) {
        if (sp.geometry_id) |geo_id| {
            c.glDetachShader(sp.program_id, geo_id);
        }
        c.glDetachShader(sp.program_id, sp.fragment_id);
        c.glDetachShader(sp.program_id, sp.vertex_id);

        if (sp.geometry_id) |geo_id| {
            c.glDeleteShader(geo_id);
        }
        c.glDeleteShader(sp.fragment_id);
        c.glDeleteShader(sp.vertex_id);

        c.glDeleteProgram(sp.program_id);
    }
};

pub fn createAllShaders() -> AllShaders {
    var as : AllShaders = undefined;

    as.primitive = createShader(
        \\#version 150 core
        \\
        \\in vec3 VertexPosition;
        \\
        \\uniform mat4 MVP;
        \\
        \\void main(void) {
        \\    gl_Position = vec4(VertexPosition, 1.0) * MVP;
        \\}
    ,
        \\#version 150 core
        \\
        \\out vec4 FragColor;
        \\
        \\uniform vec4 Color;
        \\
        \\void main(void) {
        \\    FragColor = Color;
        \\}
    , null);

    as.primitive_attrib_position = as.primitive.attrib_location(c"VertexPosition");
    as.primitive_uniform_mvp = as.primitive.uniform_location(c"MVP");
    as.primitive_uniform_color = as.primitive.uniform_location(c"Color");



    as.texture = createShader(
        \\#version 150 core
        \\
        \\in vec3 VertexPosition;
        \\in vec2 TexCoord;
        \\
        \\out vec2 FragTexCoord;
        \\
        \\uniform mat4 MVP;
        \\
        \\void main(void)
        \\{
        \\    FragTexCoord = TexCoord;
        \\    gl_Position = vec4(VertexPosition, 1.0) * MVP;
        \\}
    ,
        \\#version 150 core
        \\
        \\in vec2 FragTexCoord;
        \\out vec4 FragColor;
        \\
        \\uniform sampler2D Tex;
        \\
        \\void main(void)
        \\{
        \\    FragColor = texture(Tex, FragTexCoord);
        \\}
    , null);

    as.texture_attrib_tex_coord = as.texture.attrib_location(c"TexCoord");
    as.texture_attrib_position = as.texture.attrib_location(c"VertexPosition");
    as.texture_uniform_mvp = as.texture.uniform_location(c"MVP");
    as.texture_uniform_tex = as.texture.uniform_location(c"Tex");

    debug_gl.assertNoError();

    return as;
}

pub fn createShader(vertex_source: []const u8, frag_source: []const u8,
                     maybe_geometry_source: ?[]u8) -> ShaderProgram
{
    var sp : ShaderProgram = undefined;
    sp.vertex_id = init_shader(vertex_source, c"vertex", c.GL_VERTEX_SHADER);
    sp.fragment_id = init_shader(frag_source, c"fragment", c.GL_FRAGMENT_SHADER);
    sp.geometry_id = if (maybe_geometry_source) |geo_source| {
        init_shader(geo_source, c"geometry", c.GL_GEOMETRY_SHADER)
    } else {
        null
    };

    sp.program_id = c.glCreateProgram();
    c.glAttachShader(sp.program_id, sp.vertex_id);
    c.glAttachShader(sp.program_id, sp.fragment_id);
    if (sp.geometry_id) |geo_id| {
        c.glAttachShader(sp.program_id, geo_id);
    }
    c.glLinkProgram(sp.program_id);

    var ok: c.GLint = undefined;
    c.glGetProgramiv(sp.program_id, c.GL_LINK_STATUS, &ok);
    if (ok != 0) return sp;

    var error_size: c.GLint = undefined;
    c.glGetProgramiv(sp.program_id, c.GL_INFO_LOG_LENGTH, &error_size);
    const message = %%mem.alloc(u8, usize(error_size));
    c.glGetProgramInfoLog(sp.program_id, error_size, &error_size, &message[0]);
    _ = c.printf(c"Error linking shader program: %s\n", &message[0]);
    os.abort();
}

fn init_shader(source: []const u8, name: &const u8, kind: c.GLenum) -> c.GLuint {
    const shader_id = c.glCreateShader(kind);
    const source_ptr: ?&const u8 = &source[0];
    const source_len = c.GLint(source.len);
    c.glShaderSource(shader_id, 1, &source_ptr, &source_len);
    c.glCompileShader(shader_id);

    var ok: c.GLint = undefined;
    c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &ok);
    if (ok != 0) return shader_id;

    var error_size: c.GLint = undefined;
    c.glGetShaderiv(shader_id, c.GL_INFO_LOG_LENGTH, &error_size);

    const message = %%mem.alloc(u8, usize(error_size));
    c.glGetShaderInfoLog(shader_id, error_size, &error_size, &message[0]);
    _ = c.printf(c"Error compiling %s shader:\n%s\n", name, &message[0]);
    os.abort();
}

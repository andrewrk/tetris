const std = @import("std");
const os = std.os;
const panic = std.debug.panic;
const c = @import("c.zig");
const math3d = @import("math3d.zig");
const debug_gl = @import("debug_gl.zig");
const Vec4 = math3d.Vec4;
const Mat4x4 = math3d.Mat4x4;
const c_allocator = @import("std").heap.c_allocator;

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

    pub fn create() !AllShaders {
        var as: AllShaders = undefined;

        as.primitive = try ShaderProgram.create(
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

        as.primitive_attrib_position = as.primitive.attribLocation("VertexPosition");
        as.primitive_uniform_mvp = as.primitive.uniformLocation("MVP");
        as.primitive_uniform_color = as.primitive.uniformLocation("Color");

        as.texture = try ShaderProgram.create(
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

        as.texture_attrib_tex_coord = as.texture.attribLocation("TexCoord");
        as.texture_attrib_position = as.texture.attribLocation("VertexPosition");
        as.texture_uniform_mvp = as.texture.uniformLocation("MVP");
        as.texture_uniform_tex = as.texture.uniformLocation("Tex");

        debug_gl.assertNoError();

        return as;
    }

    pub fn destroy(as: *AllShaders) void {
        as.primitive.destroy();
        as.texture.destroy();
    }
};

pub const ShaderProgram = struct {
    program_id: c.GLuint,
    vertex_id: c.GLuint,
    fragment_id: c.GLuint,
    maybe_geometry_id: ?c.GLuint,

    pub fn bind(sp: ShaderProgram) void {
        c.glUseProgram(sp.program_id);
    }

    pub fn attribLocation(sp: ShaderProgram, name: [*]const u8) c.GLint {
        const id = c.glGetAttribLocation(sp.program_id, name);
        if (id == -1) {
            panic("invalid attrib: {}\n", .{name});
        }
        return id;
    }

    pub fn uniformLocation(sp: ShaderProgram, name: [*]const u8) c.GLint {
        const id = c.glGetUniformLocation(sp.program_id, name);
        if (id == -1) {
            panic("invalid uniform: {}\n", .{name});
        }
        return id;
    }

    pub fn setUniformInt(sp: ShaderProgram, uniform_id: c.GLint, value: c_int) void {
        c.glUniform1i(uniform_id, value);
    }

    pub fn setUniformFloat(sp: ShaderProgram, uniform_id: c.GLint, value: f32) void {
        c.glUniform1f(uniform_id, value);
    }

    pub fn setUniformVec3(sp: ShaderProgram, uniform_id: c.GLint, value: math3d.Vec3) void {
        c.glUniform3fv(uniform_id, 1, &value.data[0]);
    }

    pub fn setUniformVec4(sp: ShaderProgram, uniform_id: c.GLint, value: Vec4) void {
        c.glUniform4fv(uniform_id, 1, &value.data[0]);
    }

    pub fn setUniformMat4x4(sp: ShaderProgram, uniform_id: c.GLint, value: Mat4x4) void {
        c.glUniformMatrix4fv(uniform_id, 1, c.GL_FALSE, &value.data[0][0]);
    }

    pub fn create(
        vertex_source: []const u8,
        frag_source: []const u8,
        maybe_geometry_source: ?[]u8,
    ) !ShaderProgram {
        var sp: ShaderProgram = undefined;
        sp.vertex_id = try initGlShader(vertex_source, "vertex", c.GL_VERTEX_SHADER);
        sp.fragment_id = try initGlShader(frag_source, "fragment", c.GL_FRAGMENT_SHADER);
        sp.maybe_geometry_id = if (maybe_geometry_source) |geo_source|
            try initGlShader(geo_source, "geometry", c.GL_GEOMETRY_SHADER)
        else
            null;

        sp.program_id = c.glCreateProgram();
        c.glAttachShader(sp.program_id, sp.vertex_id);
        c.glAttachShader(sp.program_id, sp.fragment_id);
        if (sp.maybe_geometry_id) |geo_id| {
            c.glAttachShader(sp.program_id, geo_id);
        }
        c.glLinkProgram(sp.program_id);

        var ok: c.GLint = undefined;
        c.glGetProgramiv(sp.program_id, c.GL_LINK_STATUS, &ok);
        if (ok != 0) return sp;

        var error_size: c.GLint = undefined;
        c.glGetProgramiv(sp.program_id, c.GL_INFO_LOG_LENGTH, &error_size);
        const message = try c_allocator.alloc(u8, @intCast(usize, error_size));
        c.glGetProgramInfoLog(sp.program_id, error_size, &error_size, message.ptr);
        panic("Error linking shader program: {}\n", .{message.ptr});
    }

    pub fn destroy(sp: *ShaderProgram) void {
        if (sp.maybe_geometry_id) |geo_id| {
            c.glDetachShader(sp.program_id, geo_id);
        }
        c.glDetachShader(sp.program_id, sp.fragment_id);
        c.glDetachShader(sp.program_id, sp.vertex_id);

        if (sp.maybe_geometry_id) |geo_id| {
            c.glDeleteShader(geo_id);
        }
        c.glDeleteShader(sp.fragment_id);
        c.glDeleteShader(sp.vertex_id);

        c.glDeleteProgram(sp.program_id);
    }
};

fn initGlShader(source: []const u8, name: [*]const u8, kind: c.GLenum) !c.GLuint {
    const shader_id = c.glCreateShader(kind);
    const source_ptr: ?[*]const u8 = source.ptr;
    const source_len = @intCast(c.GLint, source.len);
    c.glShaderSource(shader_id, 1, &source_ptr, &source_len);
    c.glCompileShader(shader_id);

    var ok: c.GLint = undefined;
    c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &ok);
    if (ok != 0) return shader_id;

    var error_size: c.GLint = undefined;
    c.glGetShaderiv(shader_id, c.GL_INFO_LOG_LENGTH, &error_size);

    const message = try c_allocator.alloc(u8, @intCast(usize, error_size));
    c.glGetShaderInfoLog(shader_id, error_size, &error_size, message.ptr);
    panic("Error compiling {} shader:\n{}\n", .{ name, message.ptr });
}

import "libc.zig";
import "math3d.zig";
import "debug_gl.zig";

pub struct AllShaders {
    primitive: ShaderProgram,
    primitive_attrib_position: GLint,
    primitive_uniform_mvp: GLint,
    primitive_uniform_color: GLint,

    pub fn destroy(as: &AllShaders) {
        as.primitive.destroy();
    }
}

pub struct ShaderProgram {
    program_id: GLuint,
    vertex_id: GLuint,
    fragment_id: GLuint,
    geometry_id: ?GLuint,
    

    pub fn bind(sp: ShaderProgram) {
        glUseProgram(sp.program_id);
    }

    pub fn attrib_location(sp: ShaderProgram, name: &const u8) -> GLint {
        const id = glGetAttribLocation(sp.program_id, name);
        if (id == -1) {
            fprintf(stderr, c"invalid attrib: %s\n", name);
            abort();
        }
        return id;
    }

    pub fn uniform_location(sp: ShaderProgram, name: &const u8) -> GLint {
        const id = glGetUniformLocation(sp.program_id, name);
        if (id == -1) {
            fprintf(stderr, c"invalid uniform: %s\n", name);
            abort();
        }
        return id;
    }

    pub fn set_uniform_int(sp: ShaderProgram, uniform_id: GLint, value: c_int) {
        glUniform1i(uniform_id, value);
    }

    pub fn set_uniform_float(sp: ShaderProgram, uniform_id: GLint, value: f32) {
        glUniform1f(uniform_id, value);
    }

    pub fn set_uniform_vec3(sp: ShaderProgram, uniform_id: GLint, value: Vec3) {
        glUniform3fv(uniform_id, 1, &value.data[0]);
    }

    pub fn set_uniform_vec4(sp: ShaderProgram, uniform_id: GLint, value: Vec4) {
        glUniform4fv(uniform_id, 1, &value.data[0]);
    }

    pub fn set_uniform_mat4x4(sp: ShaderProgram, uniform_id: GLint, value: Mat4x4) {
        glUniformMatrix4fv(uniform_id, 1, GL_FALSE, &value.data[0][0]);
    }

    pub fn destroy(sp: &ShaderProgram) {
        if (var geo_id ?= sp.geometry_id) {
            glDetachShader(sp.program_id, geo_id);
        }
        glDetachShader(sp.program_id, sp.fragment_id);
        glDetachShader(sp.program_id, sp.vertex_id);

        if (var geo_id ?= sp.geometry_id) {
            glDeleteShader(geo_id);
        }
        glDeleteShader(sp.fragment_id);
        glDeleteShader(sp.vertex_id);

        glDeleteProgram(sp.program_id);
    }
}

pub fn create_all_shaders() -> AllShaders {
    var as : AllShaders = undefined;

    // TODO multiline strings
    as.primitive = create_shader("
#version 150 core

in vec3 VertexPosition;

uniform mat4 MVP;

void main(void) {
    gl_Position = vec4(VertexPosition, 1.0) * MVP;
}", "
#version 150 core

out vec4 FragColor;

uniform vec4 Color;

void main(void) {
    FragColor = Color;
}", null);

    as.primitive_attrib_position = as.primitive.attrib_location(c"VertexPosition");
    as.primitive_uniform_mvp = as.primitive.uniform_location(c"MVP");
    as.primitive_uniform_color = as.primitive.uniform_location(c"Color");

    assert_no_gl_error();

    return as;
}

pub fn create_shader(vertex_source: []u8, frag_source: []u8,
                     maybe_geometry_source: ?[]u8) -> ShaderProgram
{
    var sp : ShaderProgram = undefined;
    sp.vertex_id = init_shader(vertex_source, c"vertex", GL_VERTEX_SHADER);
    sp.fragment_id = init_shader(frag_source, c"fragment", GL_FRAGMENT_SHADER);
    sp.geometry_id = if (const geo_source ?= maybe_geometry_source) {
        init_shader(geo_source, c"geometry", GL_GEOMETRY_SHADER)
    } else {
        null
    };

    sp.program_id = glCreateProgram();
    glAttachShader(sp.program_id, sp.vertex_id);
    glAttachShader(sp.program_id, sp.fragment_id);
    if (const geo_id ?= sp.geometry_id) {
        glAttachShader(sp.program_id, geo_id);
    }
    glLinkProgram(sp.program_id);

    var ok: GLint = undefined;
    glGetProgramiv(sp.program_id, GL_LINK_STATUS, &ok);
    if (ok != 0) return sp;

    var error_size: GLint = undefined;
    glGetProgramiv(sp.program_id, GL_INFO_LOG_LENGTH, &error_size);
    var message: [error_size]u8 = undefined;
    glGetProgramInfoLog(sp.program_id, error_size, &error_size, &message[0]);
    fprintf(stderr, c"Error linking shader program: %s\n", &message[0]);
    abort();
}

fn init_shader(source: []u8, name: &const u8, kind: GLenum) -> GLuint {
    const shader_id = glCreateShader(kind);
    const source_ptr : ?&const GLchar = &source[0];
    const source_len = GLint(source.len);
    glShaderSource(shader_id, 1, &source_ptr, &source_len);
    glCompileShader(shader_id);

    var ok: GLint = undefined;
    glGetShaderiv(shader_id, GL_COMPILE_STATUS, &ok);
    if (ok != 0) return shader_id;

    var error_size: GLint = undefined;
    glGetShaderiv(shader_id, GL_INFO_LOG_LENGTH, &error_size);

    var message: [error_size]u8 = undefined;
    glGetShaderInfoLog(shader_id, error_size, &error_size, &message[0]);
    fprintf(stderr, c"Error compiling %s shader:\n%s\n", name, &message[0]);
    abort();
}

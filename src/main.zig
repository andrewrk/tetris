#link("c")
#link("glfw")
#link("epoxy")
export executable "tetris";

import "math3d.zig";
import "libc.zig";

struct Vertex {
    x: f32,
    y: f32,
    r: f32,
    g: f32,
    b: f32,
}

const vertices = []Vertex {
    Vertex { .x = -0.6, .y = -0.4, .r = 1.0, .g = 0.0, .b = 0.0 },
    Vertex { .x =  0.6, .y = -0.4, .r = 0.0, .g = 1.0, .b = 0.0 },
    Vertex { .x =  0.0, .y =  0.6, .r = 0.0, .g = 0.0, .b = 1.0 },
};

const vertex_shader_text =
"uniform mat4 MVP;\n" ++
"attribute vec3 vCol;\n" ++
"attribute vec2 vPos;\n" ++
"varying vec3 color;\n" ++
"void main()\n" ++
"{\n" ++
"    gl_Position = MVP * vec4(vPos, 0.0, 1.0);\n" ++
"    color = vCol;\n" ++
"}\n";

const fragment_shader_text =
"varying vec3 color;\n" ++
"void main()\n" ++
"{\n" ++
"    gl_FragColor = vec4(color, 1.0);\n" ++
"}\n";

export fn tetris_error_callback(err: c_int, description: ?&const u8) {
    fprintf(stderr, c"Error: %s\n", description);
}

export fn tetris_key_callback(window: ?&GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GL_TRUE);
    }
}

export fn main(argc: c_int, argv: &&u8) -> c_int {
    glfwSetErrorCallback(tetris_error_callback);

    if (glfwInit() == GL_FALSE)
        return -1;

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    var window = glfwCreateWindow(640, 480, c"Tetris", null, null) ?? {
        glfwTerminate();
        return -1;
    };

    glfwSetKeyCallback(window, tetris_key_callback);

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // NOTE: OpenGL error checks have been omitted for brevity

    var vertex_buffer : GLuint = undefined;
    glGenBuffers(1, &vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, @sizeof(Vertex) * vertices.len, (&const c_void)(vertices.ptr), GL_STATIC_DRAW);

    const vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    const vertex_shader_text_ptr : ?&const GLchar = vertex_shader_text.ptr;
    const vertex_shader_text_len = GLint(vertex_shader_text.len);
    glShaderSource(vertex_shader, 1, &vertex_shader_text_ptr, &vertex_shader_text_len);
    glCompileShader(vertex_shader);

    const fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    const fragment_shader_text_ptr : ?&const GLchar = fragment_shader_text.ptr;
    const fragment_shader_text_len = GLint(fragment_shader_text.len);
    glShaderSource(fragment_shader, 1, &fragment_shader_text_ptr, &fragment_shader_text_len);
    glCompileShader(fragment_shader);

    var program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    const mvp_location = glGetUniformLocation(program, c"MVP");
    const vpos_location = glGetAttribLocation(program, c"vPos");
    const vcol_location = glGetAttribLocation(program, c"vCol");

    glEnableVertexAttribArray(GLuint(vpos_location));
    glVertexAttribPointer(GLuint(vpos_location), 2, GL_FLOAT, GL_FALSE,
                          @sizeof(f32) * 5, null);
    glEnableVertexAttribArray(GLuint(vcol_location));
    glVertexAttribPointer(GLuint(vcol_location), 3, GL_FLOAT, GL_FALSE,
                          @sizeof(f32) * 5, (&const c_void)(isize(@sizeof(f32) * 2)));

    while (glfwWindowShouldClose(window) == GL_FALSE) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        glfwGetFramebufferSize(window, &width, &height);
        const ratio = f32(width) / f32(height);

        glViewport(0, 0, width, height);
        glClear(GL_COLOR_BUFFER_BIT);

        const model = mat4x4_identity().rotate(f32(glfwGetTime()), vec3_new(0.0, 0.0, 1.0));
        //const projection = mat4x4_ortho(0.0, f32(width), f32(height), 0.0);
        const projection = mat4x4_ortho(0.0, 1.0, 0.0, 1.0);
        const mvp = projection.mult(model);

        glUseProgram(program);
        glUniformMatrix4fv(mvp_location, 1, GL_FALSE, (&const GLfloat)(mvp.data.ptr));
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);

    glfwTerminate();
    return 0;
}

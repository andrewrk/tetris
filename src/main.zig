export executable "tetris";

// Zig features needed to make this example work:
// * f32 literals.
// * c_int
// * Including C header files.
// * Global struct initializers.
// * Here document or string concatenation.

#c_include("epoxy/gl.h");
#c_include("epoxy/glx.h");
#c_include("GLFW/glfw3.h");
#c_include("stdlib.h");
#c_include("stdio.h");

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

const vertex_shader_text: []u8 =
"uniform mat4 MVP;\n" ++
"attribute vec3 vCol;\n" ++
"attribute vec2 vPos;\n" ++
"varying vec3 color;\n" ++
"void main()\n" ++
"{\n" ++
"    gl_Position = MVP * vec4(vPos, 0.0, 1.0);\n" ++
"    color = vCol;\n" ++
"}\n";

const fragment_shader_text: []u8 =
"varying vec3 color;\n" ++
"void main()\n" ++
"{\n" ++
"    gl_FragColor = vec4(color, 1.0);\n" ++
"}\n";

export fn error_callback(error: c_int, description: &const u8) => {
    fprintf(stderr, "Error: %s\n", description);
}

export fn key_callback(window: &GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) => {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

pub fn main(args: [][]u8) i32 => {
    glfwSetErrorCallback(error_callback);

    if (!glfwInit())
        return -1;

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    var window = glfwCreateWindow(640, 480, "Simple example", NULL, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    glfwSetKeyCallback(window, key_callback);

    glfwMakeContextCurrent(window);
    gladLoadGLLoader(GLADloadproc(glfwGetProcAddress));
    glfwSwapInterval(1);

    // NOTE: OpenGL error checks have been omitted for brevity

    glGenBuffers(1, &vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, @sizeof(Vertex) * vertices.len, vertices, GL_STATIC_DRAW);

    vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex_shader, 1, &vertex_shader_text, NULL);
    glCompileShader(vertex_shader);

    fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment_shader, 1, &fragment_shader_text, NULL);
    glCompileShader(fragment_shader);

    var program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    var mvp_location = glGetUniformLocation(program, "MVP");
    var vpos_location = glGetAttribLocation(program, "vPos");
    var vcol_location = glGetAttribLocation(program, "vCol");

    glEnableVertexAttribArray(vpos_location);
    glVertexAttribPointer(vpos_location, 2, GL_FLOAT, GL_FALSE,
                          @sizeof(f32) * 5, null);
    glEnableVertexAttribArray(vcol_location);
    glVertexAttribPointer(vcol_location, 3, GL_FLOAT, GL_FALSE,
                          @sizeof(f32) * 5, (&u8)(@sizeof(f32) * 2));

    while (!glfwWindowShouldClose(window)) {
        var width: c_int;
        var height: c_int;
        glfwGetFramebufferSize(window, &width, &height);
        const ratio = width / f32(height);

        glViewport(0, 0, width, height);
        glClear(GL_COLOR_BUFFER_BIT);

        var m: mat4x4;
        var p: mat4x4;
        var mvp: mat4x4;

        mat4x4_identity(m);
        mat4x4_rotate_Z(m, m, f32(glfwGetTime()));
        mat4x4_ortho(p, -ratio, ratio, -1.0, 1.0, 1.0, -1.0);
        mat4x4_mul(mvp, p, m);

        glUseProgram(program);
        glUniformMatrix4fv(mvp_location, 1, GL_FALSE, (&const GLfloat)(mvp));
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);

    glfwTerminate();
    return 0;
}

#link("c")
#link("glfw")
#link("epoxy")
export executable "tetris";

import "math3d.zig";
import "libc.zig";
import "all_shaders.zig";
import "static_geometry.zig";
import "debug_gl.zig";

struct Tetris {
    window: &GLFWwindow,
    shaders: AllShaders,
    static_geometry: StaticGeometry,
    projection: Mat4x4,
}

// TODO avoid having to make this function export
export fn tetris_error_callback(err: c_int, description: ?&const u8) {
    fprintf(stderr, c"Error: %s\n", description);
    abort();
}

// TODO avoid having to make this function export
export fn tetris_key_callback(window: ?&GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GL_TRUE);
    }
}

export fn main(argc: c_int, argv: &&u8) -> c_int {
    // TODO this crashes the compiler:
    // const gl_debug_on = if (@compile_var("is_release")) GL_FALSE else GL_TRUE;

    glfwSetErrorCallback(tetris_error_callback);

    if (glfwInit() == GL_FALSE) {
        fprintf(stderr, c"GLFW init failure\n");
        abort();
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    const gl_debug_on : c_int = if (@compile_var("is_release")) GL_FALSE else GL_TRUE; // TODO move to const
    glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, gl_debug_on);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_DEPTH_BITS, 0);
    glfwWindowHint(GLFW_STENCIL_BITS, 8);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    var window = glfwCreateWindow(800, 450, c"Tetris", null, null) ?? {
        glfwTerminate();
        return -1;
    };

    glfwSetKeyCallback(window, tetris_key_callback);
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // create and bind exactly one vertex array per context and use
    // glVertexAttribPointer etc every frame.
    var vertex_array_object : GLuint = undefined;
    glGenVertexArrays(1, &vertex_array_object);
    glBindVertexArray(vertex_array_object);

    glClearColor(0.0, 0.0, 0.0, 1.0);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    var width: c_int = undefined;
    var height: c_int = undefined;
    glfwGetFramebufferSize(window, &width, &height);
    if (width < 800 || height < 450) unreachable{};
    const projection = mat4x4_ortho(0.0, f32(width), f32(height), 0.0);
    glViewport(0, 0, width, height);

    var t = Tetris {
        .window = window,
        .shaders = create_all_shaders(),
        .static_geometry = create_static_geometry(),
        .projection = projection,
    };
    glfwSetWindowUserPointer(window, (&c_void)(&t));

    assert_no_gl_error();

    while (glfwWindowShouldClose(window) == GL_FALSE) {
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

        const blue = vec4(0.0, 0.0, 1.0, 1.0);
        const scale = fabsf(sinf(f32(glfwGetTime())));
        fill_rect(t, blue, 100.0, scale * 100.0, 50.0, 50.0);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    t.shaders.destroy();
    t.static_geometry.destroy();
    glDeleteVertexArrays(1, &vertex_array_object);

    assert_no_gl_error();

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}

fn fill_rect_mvp(t: Tetris, color: Vec4, mvp: Mat4x4) {
    t.shaders.primitive.bind();
    t.shaders.primitive.set_uniform_vec4(t.shaders.primitive_uniform_color, color);
    t.shaders.primitive.set_uniform_mat4x4(t.shaders.primitive_uniform_mvp, mvp);

    glBindBuffer(GL_ARRAY_BUFFER, t.static_geometry.rect_2d_vertex_buffer);
    glEnableVertexAttribArray(GLuint(t.shaders.primitive_attrib_position));
    glVertexAttribPointer(GLuint(t.shaders.primitive_attrib_position), 3, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

fn fill_rect(t: Tetris, color: Vec4, x: f32, y: f32, w: f32, h: f32) {
    const model = mat4x4_identity.translate(x, y, 0.0).scale(w, h, 0.0);
    const mvp = t.projection.mult(model);
    fill_rect_mvp(t, color, mvp);
}

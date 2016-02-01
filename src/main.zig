#link("c")
#link("glfw")
export executable "tetris";

c_import {
    @c_include("GLFW/glfw3.h");
    @c_include("stdlib.h");
    @c_include("stdio.h");
}

export fn tetris_error_callback(err: c_int, description: ?&const u8) {
    fprintf(stderr, c"%s\n", description);
}

export fn tetris_key_callback(window: ?&GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GL_TRUE);
    }
}

export fn main(argc: c_int, argv: &&u8) -> c_int {
    glfwSetErrorCallback(tetris_error_callback);

    if (glfwInit() != GL_TRUE) {
        fprintf(stderr, c"unable to init GLFW\n");
        return -1;
    }

    var window = glfwCreateWindow(640, 480, c"Simple example", null, null) ?? {
        glfwTerminate();
        return -1;
    };
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);
    glfwSetKeyCallback(window, tetris_key_callback);
    while (glfwWindowShouldClose(window) != GL_TRUE) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        glfwGetFramebufferSize(window, &width, &height);
        const ratio = f32(width) / f32(height);
        glViewport(0, 0, width, height);
        glClear(GL_COLOR_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(-ratio, ratio, -1.0, 1.0, 1.0, -1.0);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glRotatef(f32(glfwGetTime() * 50.0), 0.0, 0.0, 1.0);
        glBegin(GL_TRIANGLES);
        glColor3f(1.0, 0.0, 0.0);
        glVertex3f(-0.6, -0.4, 0.0);
        glColor3f(0.0, 1.0, 0.0);
        glVertex3f(0.6, -0.4, 0.0);
        glColor3f(0.0, 0.0, 1.0);
        glVertex3f(0.0, 0.6, 0.0);
        glEnd();
        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}

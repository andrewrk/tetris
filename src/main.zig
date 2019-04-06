use @import("math3d.zig");

const c = @import("c.zig");
const debug_gl = @import("debug_gl.zig");
const std = @import("std");
const tetris = @import("tetris.zig");

const AllShaders = @import("all_shaders.zig").AllShaders;
const StaticGeometry = @import("static_geometry.zig").StaticGeometry;
const Spritesheet = @import("spritesheet.zig").Spritesheet;
const Particle = @import("tetris.zig").Particle;
const Piece = @import("pieces.zig").Piece;

const assert = std.debug.assert;
const bufPrint = std.fmt.bufPrint;
const os = std.os;
const panic = std.debug.panic;

const font_png = @embedFile("../assets/font.png");

const GlfwTetris = struct {
    base: tetris.Tetris,
    window: *c.GLFWwindow,
    all_shaders: AllShaders,
    static_geometry: StaticGeometry,
    font: Spritesheet,
};

pub fn main() !void {
    var tetris_state: GlfwTetris = undefined;
    const t = &tetris_state;

    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() == c.GL_FALSE) {
        panic("GLFW init failure\n");
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 2);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_DEPTH_BITS, 0);
    c.glfwWindowHint(c.GLFW_STENCIL_BITS, 8);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);

    t.window = c.glfwCreateWindow(tetris.window_width, tetris.window_height, c"Tetris", null, null) orelse {
        panic("unable to create window\n");
    };
    defer c.glfwDestroyWindow(t.window);

    c.glfwGetFramebufferSize(t.window, &t.base.framebuffer_width, &t.base.framebuffer_height);
    assert(t.base.framebuffer_width >= tetris.window_width);
    assert(t.base.framebuffer_height >= tetris.window_height);

    _ = c.glfwSetKeyCallback(t.window, keyCallback);
    c.glfwMakeContextCurrent(t.window);
    c.glfwSwapInterval(1);

    // create and bind exactly one vertex array per context and use
    // glVertexAttribPointer etc every frame.
    var vertex_array_object: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vertex_array_object);
    c.glBindVertexArray(vertex_array_object);
    defer c.glDeleteVertexArrays(1, &vertex_array_object);

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    c.glViewport(0, 0, t.base.framebuffer_width, t.base.framebuffer_height);
    c.glfwSetWindowUserPointer(t.window, @ptrCast(*c_void, t));

    debug_gl.assertNoError();

    t.all_shaders = try AllShaders.create();
    defer t.all_shaders.destroy();

    t.static_geometry = StaticGeometry.create();
    defer t.static_geometry.destroy();

    t.font.init(font_png, tetris.font_char_width, tetris.font_char_height) catch {
        panic("unable to read assets\n");
    };
    defer t.font.deinit();

    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    os.getRandomBytes(seed_bytes[0..]) catch |err| {
        panic("unable to seed random number generator: {}", err);
    };
    t.base.prng = std.rand.DefaultPrng.init(std.mem.readIntNative(u64, &seed_bytes));
    t.base.rand = &t.base.prng.random;

    t.base.resetProjection();

    t.base.restartGame();

    const start_time = c.glfwGetTime();
    var prev_time = start_time;

    while (c.glfwWindowShouldClose(t.window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);

        const now_time = c.glfwGetTime();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        t.base.nextFrame(elapsed);

        t.base.draw(@ptrCast(*u64, t), drawParticlePixels, drawRectanglePixels, drawTextPixels);

        c.glfwSwapBuffers(t.window);

        c.glfwPollEvents();
    }

    debug_gl.assertNoError();
}

extern fn errorCallback(err: c_int, description: [*c]const u8) void {
    panic("Error: {}\n", description);
}

extern fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
    if (action != c.GLFW_PRESS) return;
    const t = @ptrCast(*GlfwTetris, @alignCast(@alignOf(GlfwTetris), c.glfwGetWindowUserPointer(window).?));

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
        c.GLFW_KEY_SPACE => t.base.userDropCurPiece(),
        c.GLFW_KEY_DOWN => t.base.userCurPieceFall(),
        c.GLFW_KEY_LEFT => t.base.userMoveCurPiece(-1),
        c.GLFW_KEY_RIGHT => t.base.userMoveCurPiece(1),
        c.GLFW_KEY_UP => t.base.userRotateCurPiece(1),
        c.GLFW_KEY_LEFT_SHIFT, c.GLFW_KEY_RIGHT_SHIFT => t.base.userRotateCurPiece(-1),
        c.GLFW_KEY_R => t.base.restartGame(),
        c.GLFW_KEY_P => t.base.userTogglePause(),
        c.GLFW_KEY_LEFT_CONTROL, c.GLFW_KEY_RIGHT_CONTROL => t.base.userSetHoldPiece(),
        else => {},
    }
}

fn drawParticlePixels(callback_user_pointer: *u64, p: Particle) void {
    const t = @ptrCast(*GlfwTetris, callback_user_pointer);
    const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);

    const mvp = t.base.projection.mult(model);

    t.all_shaders.primitive.bind();
    t.all_shaders.primitive.setUniformVec4(t.all_shaders.primitive_uniform_color, p.color);
    t.all_shaders.primitive.setUniformMat4x4(t.all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, t.static_geometry.triangle_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 3);
}

fn drawRectanglePixels(callback_user_pointer: *u64, color: Vec4, mvp: Mat4x4) void {
    const t = @ptrCast(*GlfwTetris, callback_user_pointer);
    t.all_shaders.primitive.bind();
    t.all_shaders.primitive.setUniformVec4(t.all_shaders.primitive_uniform_color, color);
    t.all_shaders.primitive.setUniformMat4x4(t.all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, t.static_geometry.rect_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
}

fn drawTextPixels(callback_user_pointer: *u64, text: []const u8, left: i32, top: i32, size: f32) void {
    const t = @ptrCast(*GlfwTetris, callback_user_pointer);
    for (text) |col, i| {
        if (col <= '~') {
            const char_left = @intToFloat(f32, left) + @intToFloat(f32, @intCast(i32, i) * tetris.font_char_width) * size;
            const model = mat4x4_identity.translate(char_left, @intToFloat(f32, top), 0.0).scale(size, size, 0.0);
            const mvp = t.base.projection.mult(model);

            t.font.draw(t.all_shaders, col, mvp);
        } else {
            unreachable;
        }
    }
}

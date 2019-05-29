use @import("math3d.zig");
use @import("tetris.zig");

const std = @import("std");
const panic = std.debug.panic;
const assert = std.debug.assert;
const bufPrint = std.fmt.bufPrint;
const c = @import("c.zig");
const debug_gl = @import("debug_gl.zig");
const AllShaders = @import("all_shaders.zig").AllShaders;
const StaticGeometry = @import("static_geometry.zig").StaticGeometry;
const pieces = @import("pieces.zig");
const Piece = pieces.Piece;
const Spritesheet = @import("spritesheet.zig").Spritesheet;

var window: *c.GLFWwindow = undefined;
var all_shaders: AllShaders = undefined;
var static_geometry: StaticGeometry = undefined;
var font: Spritesheet = undefined;

extern fn errorCallback(err: c_int, description: [*c]const u8) void {
    panic("Error: {}\n", description);
}

extern fn keyCallback(win: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
    if (action != c.GLFW_PRESS) return;
    const t = @ptrCast(*Tetris, @alignCast(@alignOf(Tetris), c.glfwGetWindowUserPointer(win).?));

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(win, c.GL_TRUE),
        c.GLFW_KEY_SPACE => userDropCurPiece(t),
        c.GLFW_KEY_DOWN => userCurPieceFall(t),
        c.GLFW_KEY_LEFT => userMoveCurPiece(t, -1),
        c.GLFW_KEY_RIGHT => userMoveCurPiece(t, 1),
        c.GLFW_KEY_UP => userRotateCurPiece(t, 1),
        c.GLFW_KEY_LEFT_SHIFT, c.GLFW_KEY_RIGHT_SHIFT => userRotateCurPiece(t, -1),
        c.GLFW_KEY_R => restartGame(t),
        c.GLFW_KEY_P => userTogglePause(t),
        c.GLFW_KEY_LEFT_CONTROL, c.GLFW_KEY_RIGHT_CONTROL => userSetHoldPiece(t),
        else => {},
    }
}

var tetris_state: Tetris = undefined;

const font_png = @embedFile("../assets/font.png");

pub fn main() !void {
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

    window = c.glfwCreateWindow(window_width, window_height, c"Tetris", null, null) orelse {
        panic("unable to create window\n");
    };
    defer c.glfwDestroyWindow(window);

    _ = c.glfwSetKeyCallback(window, keyCallback);
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    // create and bind exactly one vertex array per context and use
    // glVertexAttribPointer etc every frame.
    var vertex_array_object: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vertex_array_object);
    c.glBindVertexArray(vertex_array_object);
    defer c.glDeleteVertexArrays(1, &vertex_array_object);

    const t = &tetris_state;
    c.glfwGetFramebufferSize(window, &t.framebuffer_width, &t.framebuffer_height);
    assert(t.framebuffer_width >= window_width);
    assert(t.framebuffer_height >= window_height);

    all_shaders = try AllShaders.create();
    defer all_shaders.destroy();

    static_geometry = StaticGeometry.create();
    defer static_geometry.destroy();

    font.init(font_png, font_char_width, font_char_height) catch {
        panic("unable to read assets\n");
    };
    defer font.deinit();

    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    std.crypto.randomBytes(seed_bytes[0..]) catch |err| {
        panic("unable to seed random number generator: {}", err);
    };
    t.prng = std.rand.DefaultPrng.init(std.mem.readIntNative(u64, &seed_bytes));
    t.rand = &t.prng.random;

    resetProjection(t);

    restartGame(t);

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    c.glViewport(0, 0, t.framebuffer_width, t.framebuffer_height);
    c.glfwSetWindowUserPointer(window, @ptrCast(*c_void, t));

    debug_gl.assertNoError();

    const start_time = c.glfwGetTime();
    var prev_time = start_time;

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);

        const now_time = c.glfwGetTime();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        nextFrame(t, elapsed);

        draw(t, @This());
        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    debug_gl.assertNoError();
}

pub fn fillRectMvp(t: *Tetris, color: Vec4, mvp: Mat4x4) void {
    all_shaders.primitive.bind();
    all_shaders.primitive.setUniformVec4(all_shaders.primitive_uniform_color, color);
    all_shaders.primitive.setUniformMat4x4(all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, static_geometry.rect_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
}

pub fn drawParticle(t: *Tetris, p: Particle) void {
    const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);

    const mvp = t.projection.mult(model);

    all_shaders.primitive.bind();
    all_shaders.primitive.setUniformVec4(all_shaders.primitive_uniform_color, p.color);
    all_shaders.primitive.setUniformMat4x4(all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, static_geometry.triangle_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 3);
}

pub fn drawText(t: *Tetris, text: []const u8, left: i32, top: i32, size: f32) void {
    for (text) |col, i| {
        if (col <= '~') {
            const char_left = @intToFloat(f32, left) + @intToFloat(f32, i * font_char_width) * size;
            const model = mat4x4_identity.translate(char_left, @intToFloat(f32, top), 0.0).scale(size, size, 0.0);
            const mvp = t.projection.mult(model);

            font.draw(all_shaders, col, mvp);
        } else {
            unreachable;
        }
    }
}

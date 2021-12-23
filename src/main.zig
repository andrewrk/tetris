const math3d = @import("math3d.zig");
const Mat4x4 = math3d.Mat4x4;
const Vec3 = math3d.Vec3;
const Vec4 = math3d.Vec4;

const Tetris = @import("tetris.zig").Tetris;

const std = @import("std");
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

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    _ = err;
    _ = c.printf("Error: %s\n", description);
    c.abort();
}

fn keyCallback(
    win: ?*c.GLFWwindow,
    key: c_int,
    scancode: c_int,
    action: c_int,
    mods: c_int,
) callconv(.C) void {
    _ = mods;
    _ = scancode;
    const t = @ptrCast(*Tetris, @alignCast(@alignOf(Tetris), c.glfwGetWindowUserPointer(win).?));
    const first_delay = 0.2;

    if (action == c.GLFW_PRESS) {
        switch (key) {
            c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(win, c.GL_TRUE),
            c.GLFW_KEY_SPACE => t.userDropCurPiece(),
            c.GLFW_KEY_DOWN => {
                t.down_key_held = true;
                t.down_move_time = c.glfwGetTime() + first_delay;
                t.userCurPieceFall();
            },
            c.GLFW_KEY_LEFT => {
                t.left_key_held = true;
                t.left_move_time = c.glfwGetTime() + first_delay;
                t.userMoveCurPiece(-1);
            },
            c.GLFW_KEY_RIGHT => {
                t.right_key_held = true;
                t.right_move_time = c.glfwGetTime() + first_delay;
                t.userMoveCurPiece(1);
            },
            c.GLFW_KEY_UP => t.userRotateCurPiece(1),
            c.GLFW_KEY_LEFT_SHIFT, c.GLFW_KEY_RIGHT_SHIFT => t.userRotateCurPiece(-1),
            c.GLFW_KEY_R => t.restartGame(),
            c.GLFW_KEY_P => t.userTogglePause(),
            c.GLFW_KEY_LEFT_CONTROL, c.GLFW_KEY_RIGHT_CONTROL => t.userSetHoldPiece(),
            else => {},
        }
    } else if (action == c.GLFW_RELEASE) {
        switch (key) {
            c.GLFW_KEY_DOWN => {
                t.down_key_held = false;
            },
            c.GLFW_KEY_LEFT => {
                t.left_key_held = false;
            },
            c.GLFW_KEY_RIGHT => {
                t.right_key_held = false;
            },
            else => {},
        }
    }
}

var tetris_state: Tetris = undefined;

const font_png = @embedFile("../assets/font.png");

pub fn main() void {
    main2() catch c.abort();
}

pub fn main2() !void {
    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() == c.GL_FALSE) @panic("GLFW init failure");
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 2);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_DEPTH_BITS, 0);
    c.glfwWindowHint(c.GLFW_STENCIL_BITS, 8);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);

    window = c.glfwCreateWindow(Tetris.window_width, Tetris.window_height, "Tetris", null, null) orelse
        @panic("unable to create window");
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
    assert(t.framebuffer_width >= Tetris.window_width);
    assert(t.framebuffer_height >= Tetris.window_height);

    all_shaders = try AllShaders.create();
    defer all_shaders.destroy();

    static_geometry = StaticGeometry.create();
    defer static_geometry.destroy();

    font.init(font_png, Tetris.font_char_width, Tetris.font_char_height) catch @panic("unable to read assets");
    defer font.deinit();

    c.srand(@truncate(c_uint, @bitCast(c_ulong, c.time(null))));

    t.resetProjection();

    t.restartGame();

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    c.glViewport(0, 0, t.framebuffer_width, t.framebuffer_height);
    c.glfwSetWindowUserPointer(window, @ptrCast(*anyopaque, t));

    debug_gl.assertNoError();

    const start_time = c.glfwGetTime();
    var prev_time = start_time;

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);

        const now_time = c.glfwGetTime();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        t.doBiosKeys(now_time);
        t.nextFrame(elapsed);

        t.draw(@This());
        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    debug_gl.assertNoError();
}

pub fn fillRectMvp(color: Vec4, mvp: Mat4x4) void {
    all_shaders.primitive.bind();
    all_shaders.primitive.setUniformVec4(all_shaders.primitive_uniform_color, color);
    all_shaders.primitive.setUniformMat4x4(all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, static_geometry.rect_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
}

pub fn drawParticle(t: *Tetris, p: Tetris.Particle) void {
    const model = Mat4x4.identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);

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
            const char_left = @intToFloat(f32, left) + @intToFloat(f32, i * Tetris.font_char_width) * size;
            const model = Mat4x4.identity.translate(char_left, @intToFloat(f32, top), 0.0).scale(size, size, 0.0);
            const mvp = t.projection.mult(model);

            font.draw(all_shaders, col, mvp);
        } else {
            unreachable;
        }
    }
}

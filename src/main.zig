const std = @import("std");
const os = std.os;
const panic = std.debug.panic;
const assert = std.debug.assert;
const bufPrint = std.fmt.bufPrint;
const c = @import("c.zig");
const debug_gl = @import("debug_gl.zig");
use @import("math3d.zig");
const AllShaders = @import("all_shaders.zig").AllShaders;
const static_geometry = @import("static_geometry.zig");
const StaticGeometry = static_geometry.StaticGeometry;
const pieces = @import("pieces.zig");
const Piece = pieces.Piece;
const Spritesheet = @import("spritesheet.zig").Spritesheet;

const Tetris = struct {
    window: *c.GLFWwindow,
    all_shaders: AllShaders,
    static_geometry: StaticGeometry,
    projection: Mat4x4,
    prng: std.rand.DefaultPrng,
    rand: *std.rand.Random,
    piece_delay: f64,
    delay_left: f64,
    grid: [grid_height][grid_width]Cell,
    next_piece: *const Piece,
    hold_piece: ?*const Piece,
    hold_was_set: bool,
    cur_piece: *const Piece,
    cur_piece_x: i32,
    cur_piece_y: i32,
    cur_piece_rot: usize,
    score: c_int,
    game_over: bool,
    next_particle_index: usize,
    next_falling_block_index: usize,
    font: Spritesheet,
    ghost_y: i32,
    framebuffer_width: c_int,
    framebuffer_height: c_int,
    screen_shake_timeout: f64,
    screen_shake_elapsed: f64,
    level: i32,
    time_till_next_level: f64,
    piece_pool: [pieces.pieces.len]i32,
    is_paused: bool,

    particles: [max_particle_count]?Particle,
    falling_blocks: [max_falling_block_count]?Particle,
};

const Cell = union(enum) {
    Empty,
    Color: Vec4,
};

const Particle = struct {
    color: Vec4,
    pos: Vec3,
    vel: Vec3,
    axis: Vec3,
    scale_w: f32,
    scale_h: f32,
    angle: f32,
    angle_vel: f32,
};

const PI = 3.14159265358979;
const max_particle_count = 500;
const max_falling_block_count = grid_width * grid_height;
const margin_size = 10;
const grid_width = 10;
const grid_height = 20;
const cell_size = 32;
const board_width = grid_width * cell_size;
const board_height = grid_height * cell_size;
const board_left = margin_size;
const board_top = margin_size;

const next_piece_width = margin_size + 4 * cell_size + margin_size;
const next_piece_height = next_piece_width;
const next_piece_left = board_left + board_width + margin_size;
const next_piece_top = board_top + board_height - next_piece_height;

const score_width = next_piece_width;
const score_height = next_piece_height;
const score_left = next_piece_left;
const score_top = next_piece_top - margin_size - score_height;

const level_display_width = next_piece_width;
const level_display_height = next_piece_height;
const level_display_left = next_piece_left;
const level_display_top = score_top - margin_size - level_display_height;

const hold_piece_width = next_piece_width;
const hold_piece_height = next_piece_height;
const hold_piece_left = next_piece_left;
const hold_piece_top = level_display_top - margin_size - hold_piece_height;

const window_width = next_piece_left + next_piece_width + margin_size;
const window_height = board_top + board_height + margin_size;

const board_color = Vec4{ .data = []f32{ 72.0 / 255.0, 72.0 / 255.0, 72.0 / 255.0, 1.0 } };

const init_piece_delay = 0.5;
const min_piece_delay = 0.05;
const level_delay_increment = 0.05;

const font_char_width = 18;
const font_char_height = 32;

const gravity = 0.14;
const time_per_level = 60.0;

const empty_row = []Cell{Cell{ .Empty = {} }} ** grid_width;
const empty_grid = [][grid_width]Cell{empty_row} ** grid_height;

extern fn errorCallback(err: c_int, description: [*c]const u8) void {
    panic("Error: {}\n", description);
}

extern fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
    if (action != c.GLFW_PRESS) return;
    const t = @ptrCast(*Tetris, @alignCast(@alignOf(Tetris), c.glfwGetWindowUserPointer(window).?));

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
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

    var window = c.glfwCreateWindow(window_width, window_height, c"Tetris", null, null) orelse {
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

    t.window = window;

    t.all_shaders = try AllShaders.create();
    defer t.all_shaders.destroy();

    t.static_geometry = StaticGeometry.create();
    defer t.static_geometry.destroy();

    t.font.init(font_png, font_char_width, font_char_height) catch {
        panic("unable to read assets\n");
    };
    defer t.font.deinit();

    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    os.getRandomBytes(seed_bytes[0..]) catch |err| {
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

        draw(t);
        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    debug_gl.assertNoError();
}

fn fillRectMvp(t: *Tetris, color: Vec4, mvp: Mat4x4) void {
    t.all_shaders.primitive.bind();
    t.all_shaders.primitive.setUniformVec4(t.all_shaders.primitive_uniform_color, color);
    t.all_shaders.primitive.setUniformMat4x4(t.all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, t.static_geometry.rect_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
}

fn fillRect(t: *Tetris, color: Vec4, x: f32, y: f32, w: f32, h: f32) void {
    const model = mat4x4_identity.translate(x, y, 0.0).scale(w, h, 0.0);
    const mvp = t.projection.mult(model);
    fillRectMvp(t, color, mvp);
}

fn drawParticle(t: *Tetris, p: Particle) void {
    const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);

    const mvp = t.projection.mult(model);

    t.all_shaders.primitive.bind();
    t.all_shaders.primitive.setUniformVec4(t.all_shaders.primitive_uniform_color, p.color);
    t.all_shaders.primitive.setUniformMat4x4(t.all_shaders.primitive_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, t.static_geometry.triangle_2d_vertex_buffer);
    c.glEnableVertexAttribArray(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position));
    c.glVertexAttribPointer(@intCast(c.GLuint, t.all_shaders.primitive_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 3);
}

fn drawFallingBlock(t: *Tetris, p: Particle) void {
    const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);

    const mvp = t.projection.mult(model);

    fillRectMvp(t, p.color, mvp);
}

fn drawCenteredText(t: *Tetris, text: []const u8) void {
    const label_width = font_char_width * @intCast(i32, text.len);
    const draw_left = board_left + board_width / 2 - @divExact(label_width, 2);
    const draw_top = board_top + board_height / 2 - font_char_height / 2;
    drawText(t, text, draw_left, draw_top, 1.0);
}

fn draw(t: *Tetris) void {
    fillRect(t, board_color, board_left, board_top, board_width, board_height);
    fillRect(t, board_color, next_piece_left, next_piece_top, next_piece_width, next_piece_height);
    fillRect(t, board_color, score_left, score_top, score_width, score_height);
    fillRect(t, board_color, level_display_left, level_display_top, level_display_width, level_display_height);
    fillRect(t, board_color, hold_piece_left, hold_piece_top, hold_piece_width, hold_piece_height);

    if (t.game_over) {
        drawCenteredText(t, "GAME OVER");
    } else if (t.is_paused) {
        drawCenteredText(t, "PAUSED");
    } else {
        const abs_x = board_left + t.cur_piece_x * cell_size;
        const abs_y = board_top + t.cur_piece_y * cell_size;
        drawPiece(t, t.cur_piece.*, abs_x, abs_y, t.cur_piece_rot);

        const ghost_color = vec4(t.cur_piece.color.data[0], t.cur_piece.color.data[1], t.cur_piece.color.data[2], 0.2);
        drawPieceWithColor(t, t.cur_piece.*, abs_x, t.ghost_y, t.cur_piece_rot, ghost_color);

        drawPiece(t, t.next_piece.*, next_piece_left + margin_size, next_piece_top + margin_size, 0);
        if (t.hold_piece) |piece| {
            if (!t.hold_was_set) {
                drawPiece(t, piece.*, hold_piece_left + margin_size, hold_piece_top + margin_size, 0);
            } else {
                const grey = vec4(0.65, 0.65, 0.65, 1.0);
                drawPieceWithColor(t, piece.*, hold_piece_left + margin_size, hold_piece_top + margin_size, 0, grey);
            }
        }

        for (t.grid) |row, y| {
            for (row) |cell, x| {
                switch (cell) {
                    Cell.Color => |color| {
                        const cell_left = board_left + @intCast(i32, x) * cell_size;
                        const cell_top = board_top + @intCast(i32, y) * cell_size;
                        fillRect(
                            t,
                            color,
                            @intToFloat(f32, cell_left),
                            @intToFloat(f32, cell_top),
                            cell_size,
                            cell_size,
                        );
                    },
                    else => {},
                }
            }
        }
    }

    {
        const score_text = "SCORE:";
        const score_label_width = font_char_width * @intCast(i32, score_text.len);
        drawText(
            t,
            score_text,
            score_left + score_width / 2 - score_label_width / 2,
            score_top + margin_size,
            1.0,
        );
    }
    {
        var score_text_buf: [20]u8 = undefined;
        const score_text = bufPrint(score_text_buf[0..], "{}", t.score) catch unreachable;
        const score_label_width = font_char_width * @intCast(i32, score_text.len);
        drawText(t, score_text, score_left + score_width / 2 - @divExact(score_label_width, 2), score_top + score_height / 2, 1.0);
    }
    {
        const text = "LEVEL:";
        const text_width = font_char_width * @intCast(i32, text.len);
        drawText(t, text, level_display_left + level_display_width / 2 - text_width / 2, level_display_top + margin_size, 1.0);
    }
    {
        var text_buf: [20]u8 = undefined;
        const text = bufPrint(text_buf[0..], "{}", t.level) catch unreachable;
        const text_width = font_char_width * @intCast(i32, text.len);
        drawText(t, text, level_display_left + level_display_width / 2 - @divExact(text_width, 2), level_display_top + level_display_height / 2, 1.0);
    }
    {
        const text = "HOLD:";
        const text_width = font_char_width * @intCast(i32, text.len);
        drawText(t, text, hold_piece_left + hold_piece_width / 2 - text_width / 2, hold_piece_top + margin_size, 1.0);
    }

    for (t.falling_blocks) |maybe_particle| {
        if (maybe_particle) |particle| {
            drawFallingBlock(t, particle);
        }
    }

    for (t.particles) |maybe_particle| {
        if (maybe_particle) |particle| {
            drawParticle(t, particle);
        }
    }
}

fn drawText(t: *Tetris, text: []const u8, left: i32, top: i32, size: f32) void {
    for (text) |col, i| {
        if (col <= '~') {
            const char_left = @intToFloat(f32, left) + @intToFloat(f32, i * font_char_width) * size;
            const model = mat4x4_identity.translate(char_left, @intToFloat(f32, top), 0.0).scale(size, size, 0.0);
            const mvp = t.projection.mult(model);

            t.font.draw(t.all_shaders, col, mvp);
        } else {
            unreachable;
        }
    }
}

fn drawPiece(t: *Tetris, piece: Piece, left: i32, top: i32, rot: usize) void {
    drawPieceWithColor(t, piece, left, top, rot, piece.color);
}

fn drawPieceWithColor(t: *Tetris, piece: Piece, left: i32, top: i32, rot: usize, color: Vec4) void {
    for (piece.layout[rot]) |row, y| {
        for (row) |is_filled, x| {
            if (!is_filled) continue;
            const abs_x = @intToFloat(f32, left + @intCast(i32, x) * cell_size);
            const abs_y = @intToFloat(f32, top + @intCast(i32, y) * cell_size);

            fillRect(t, color, abs_x, abs_y, cell_size, cell_size);
        }
    }
}

fn nextFrame(t: *Tetris, elapsed: f64) void {
    if (t.is_paused) return;

    for (t.falling_blocks) |*maybe_p| {
        if (maybe_p.*) |*p| {
            p.pos = p.pos.add(p.vel);
            p.vel = p.vel.add(vec3(0, gravity, 0));

            p.angle += p.angle_vel;

            if (p.pos.data[1] > @intToFloat(f32, t.framebuffer_height)) {
                maybe_p.* = null;
            }
        }
    }

    for (t.particles) |*maybe_p| {
        if (maybe_p.*) |*p| {
            p.pos = p.pos.add(p.vel);
            p.vel = p.vel.add(vec3(0, gravity, 0));

            p.angle += p.angle_vel;

            if (p.pos.data[1] > @intToFloat(f32, t.framebuffer_height)) {
                maybe_p.* = null;
            }
        }
    }

    if (!t.game_over) {
        t.delay_left -= elapsed;

        if (t.delay_left <= 0) {
            _ = curPieceFall(t);

            t.delay_left = t.piece_delay;
        }

        t.time_till_next_level -= elapsed;
        if (t.time_till_next_level <= 0.0) {
            levelUp(t);
        }

        computeGhost(t);
    }

    if (t.screen_shake_elapsed < t.screen_shake_timeout) {
        t.screen_shake_elapsed += elapsed;
        if (t.screen_shake_elapsed >= t.screen_shake_timeout) {
            resetProjection(t);
        } else {
            const rate = 8; // oscillations per sec
            const amplitude = 4; // pixels
            const offset = @floatCast(f32, amplitude * -c.sin(2.0 * PI * t.screen_shake_elapsed * rate));
            t.projection = mat4x4Ortho(
                0.0,
                @intToFloat(f32, t.framebuffer_width),
                @intToFloat(f32, t.framebuffer_height) + offset,
                offset,
            );
        }
    }
}

fn levelUp(t: *Tetris) void {
    t.level += 1;
    t.time_till_next_level = time_per_level;

    const new_piece_delay = t.piece_delay - level_delay_increment;
    t.piece_delay = if (new_piece_delay >= min_piece_delay) new_piece_delay else min_piece_delay;

    activateScreenShake(t, 0.08);

    const max_lines_to_fill = 4;
    const proposed_lines_to_fill = @divTrunc(t.level + 2, 3);
    const lines_to_fill = if (proposed_lines_to_fill > max_lines_to_fill)
        max_lines_to_fill
    else
        proposed_lines_to_fill;

    {
        var i: i32 = 0;
        while (i < lines_to_fill) : (i += 1) {
            insertGarbageRowAtBottom(t);
        }
    }
}

fn insertGarbageRowAtBottom(t: *Tetris) void {
    // move everything up to make room at the bottom
    {
        var y: usize = 1;
        while (y < t.grid.len) : (y += 1) {
            t.grid[y - 1] = t.grid[y];
        }
    }

    // populate bottom row with garbage and make sure it fills at least
    // one and leaves at least one empty
    while (true) {
        var all_empty = true;
        var all_filled = true;
        const bottom_y = grid_height - 1;
        for (t.grid[bottom_y]) |_, x| {
            const filled = t.rand.scalar(bool);
            if (filled) {
                const index = t.rand.range(usize, 0, pieces.pieces.len);
                t.grid[bottom_y][x] = Cell{ .Color = pieces.pieces[index].color };
                all_empty = false;
            } else {
                t.grid[bottom_y][x] = Cell{ .Empty = {} };
                all_filled = false;
            }
        }
        if (!all_empty and !all_filled) break;
    }
}

fn computeGhost(t: *Tetris) void {
    var off_y: i32 = 1;
    while (!pieceWouldCollide(t, t.cur_piece.*, t.cur_piece_x, t.cur_piece_y + off_y, t.cur_piece_rot)) {
        off_y += 1;
    }
    t.ghost_y = board_top + cell_size * (t.cur_piece_y + off_y - 1);
}

fn userCurPieceFall(t: *Tetris) void {
    if (t.game_over or t.is_paused) return;
    _ = curPieceFall(t);
}

fn curPieceFall(t: *Tetris) bool {
    // if it would hit something, make it stop instead
    if (pieceWouldCollide(t, t.cur_piece.*, t.cur_piece_x, t.cur_piece_y + 1, t.cur_piece_rot)) {
        lockPiece(t);
        dropNextPiece(t);
        return true;
    } else {
        t.cur_piece_y += 1;
        return false;
    }
}

fn userDropCurPiece(t: *Tetris) void {
    if (t.game_over or t.is_paused) return;
    while (!curPieceFall(t)) {
        t.score += 1;
    }
}

fn userMoveCurPiece(t: *Tetris, dir: i8) void {
    if (t.game_over or t.is_paused) return;
    if (pieceWouldCollide(t, t.cur_piece.*, t.cur_piece_x + dir, t.cur_piece_y, t.cur_piece_rot)) {
        return;
    }
    t.cur_piece_x += dir;
}

fn userRotateCurPiece(t: *Tetris, rot: i8) void {
    if (t.game_over or t.is_paused) return;
    const new_rot = @intCast(usize, @rem(@intCast(isize, t.cur_piece_rot) + rot + 4, 4));
    if (pieceWouldCollide(t, t.cur_piece.*, t.cur_piece_x, t.cur_piece_y, new_rot)) {
        return;
    }
    t.cur_piece_rot = new_rot;
}

fn userTogglePause(t: *Tetris) void {
    if (t.game_over) return;

    t.is_paused = !t.is_paused;
}

fn restartGame(t: *Tetris) void {
    t.piece_delay = init_piece_delay;
    t.delay_left = init_piece_delay;
    t.score = 0;
    t.game_over = false;
    t.screen_shake_elapsed = 0.0;
    t.screen_shake_timeout = 0.0;
    t.level = 1;
    t.time_till_next_level = time_per_level;
    t.is_paused = false;
    t.hold_was_set = false;
    t.hold_piece = null;

    t.piece_pool = []i32{1} ** pieces.pieces.len;

    clearParticles(t);
    t.grid = empty_grid;

    populateNextPiece(t);
    dropNextPiece(t);
}

fn lockPiece(t: *Tetris) void {
    t.score += 1;

    for (t.cur_piece.layout[t.cur_piece_rot]) |row, y| {
        for (row) |is_filled, x| {
            if (!is_filled) {
                continue;
            }
            const abs_x = t.cur_piece_x + @intCast(i32, x);
            const abs_y = t.cur_piece_y + @intCast(i32, y);
            if (abs_x >= 0 and abs_y >= 0 and abs_x < grid_width and abs_y < grid_height) {
                t.grid[@intCast(usize, abs_y)][@intCast(usize, abs_x)] = Cell{ .Color = t.cur_piece.color };
            }
        }
    }

    // find lines once and spawn explosions
    for (t.grid) |row, y| {
        var all_filled = true;
        for (t.grid[y]) |cell| {
            const filled = switch (cell) {
                Cell.Empty => false,
                else => true,
            };
            if (!filled) {
                all_filled = false;
                break;
            }
        }
        if (all_filled) {
            for (t.grid[y]) |cell, x| {
                const color = switch (cell) {
                    Cell.Empty => continue,
                    Cell.Color => |col| col,
                };
                const center_x = @intToFloat(f32, board_left + x * cell_size) +
                    @intToFloat(f32, cell_size) / 2.0;
                const center_y = @intToFloat(f32, board_top + y * cell_size) +
                    @intToFloat(f32, cell_size) / 2.0;
                addExplosion(t, color, center_x, center_y);
            }
        }
    }

    // test for line
    var rows_deleted: usize = 0;
    var y: i32 = grid_height - 1;
    while (y >= 0) {
        var all_filled: bool = true;
        for (t.grid[@intCast(usize, y)]) |cell| {
            const filled = switch (cell) {
                Cell.Empty => false,
                else => true,
            };
            if (!filled) {
                all_filled = false;
                break;
            }
        }
        if (all_filled) {
            rows_deleted += 1;
            deleteRow(t, @intCast(usize, y));
        } else {
            y -= 1;
        }
    }

    const score_per_rows_deleted = []c_int{ 0, 10, 30, 50, 70 };
    t.score += score_per_rows_deleted[rows_deleted];

    if (rows_deleted > 0) {
        activateScreenShake(t, 0.04);
    }
}

fn resetProjection(t: *Tetris) void {
    t.projection = mat4x4Ortho(
        0.0,
        @intToFloat(f32, t.framebuffer_width),
        @intToFloat(f32, t.framebuffer_height),
        0.0,
    );
}

fn activateScreenShake(t: *Tetris, duration: f64) void {
    t.screen_shake_elapsed = 0.0;
    t.screen_shake_timeout = duration;
}

fn deleteRow(t: *Tetris, del_index: usize) void {
    var y: usize = del_index;
    while (y >= 1) {
        t.grid[y] = t.grid[y - 1];
        y -= 1;
    }
    t.grid[y] = empty_row;
}

fn cellEmpty(t: *Tetris, x: i32, y: i32) bool {
    return switch (t.grid[@intCast(usize, y)][@intCast(usize, x)]) {
        Cell.Empty => true,
        else => false,
    };
}

fn pieceWouldCollide(t: *Tetris, piece: Piece, grid_x: i32, grid_y: i32, rot: usize) bool {
    for (piece.layout[rot]) |row, y| {
        for (row) |is_filled, x| {
            if (!is_filled) {
                continue;
            }
            const abs_x = grid_x + @intCast(i32, x);
            const abs_y = grid_y + @intCast(i32, y);
            if (abs_x >= 0 and abs_y >= 0 and abs_x < grid_width and abs_y < grid_height) {
                if (!cellEmpty(t, abs_x, abs_y)) {
                    return true;
                }
            } else if (abs_y >= 0) {
                return true;
            }
        }
    }
    return false;
}

fn populateNextPiece(t: *Tetris) void {
    // Let's turn Gambler's Fallacy into Gambler's Accurate Model of Reality.
    var upper_bound: i32 = 0;
    for (t.piece_pool) |count| {
        if (count == 0) unreachable;
        upper_bound += count;
    }

    const rand_val = t.rand.range(i32, 0, upper_bound);
    var this_piece_upper_bound: i32 = 0;
    var any_zero = false;
    for (t.piece_pool) |count, piece_index| {
        this_piece_upper_bound += count;
        if (rand_val < this_piece_upper_bound) {
            t.next_piece = &pieces.pieces[piece_index];
            t.piece_pool[piece_index] -= 1;
            if (count <= 1) {
                any_zero = true;
            }
            break;
        }
    }

    // if any of the pieces are 0, add 1 to all of them
    if (any_zero) {
        for (t.piece_pool) |_, i| {
            t.piece_pool[i] += 1;
        }
    }
}

fn doGameOver(t: *Tetris) void {
    t.game_over = true;

    // turn every piece into a falling object
    for (t.grid) |row, y| {
        for (row) |cell, x| {
            const color = switch (cell) {
                Cell.Empty => continue,
                Cell.Color => |col| col,
            };
            const left = @intToFloat(f32, board_left + x * cell_size);
            const top = @intToFloat(f32, board_top + y * cell_size);
            t.falling_blocks[getNextFallingBlockIndex(t)] = createBlockParticle(t, color, vec3(left, top, 0.0));
        }
    }
}

fn userSetHoldPiece(t: *Tetris) void {
    if (t.game_over or t.is_paused or t.hold_was_set) return;
    var next_cur: *const Piece = undefined;
    if (t.hold_piece) |hold_piece| {
        next_cur = hold_piece;
    } else {
        next_cur = t.next_piece;
        populateNextPiece(t);
    }
    t.hold_piece = t.cur_piece;
    t.hold_was_set = true;
    dropNewPiece(t, next_cur);
}

fn dropNewPiece(t: *Tetris, p: *const Piece) void {
    const start_x = 4;
    const start_y = -1;
    const start_rot = 0;
    if (pieceWouldCollide(t, p.*, start_x, start_y, start_rot)) {
        doGameOver(t);
        return;
    }

    t.delay_left = t.piece_delay;

    t.cur_piece = p;
    t.cur_piece_x = start_x;
    t.cur_piece_y = start_y;
    t.cur_piece_rot = start_rot;
}

fn dropNextPiece(t: *Tetris) void {
    t.hold_was_set = false;
    dropNewPiece(t, t.next_piece);
    populateNextPiece(t);
}

fn clearParticles(t: *Tetris) void {
    for (t.particles) |*p| {
        p.* = null;
    }
    t.next_particle_index = 0;

    for (t.falling_blocks) |*fb| {
        fb.* = null;
    }
    t.next_falling_block_index = 0;
}

fn getNextParticleIndex(t: *Tetris) usize {
    const result = t.next_particle_index;
    t.next_particle_index = (t.next_particle_index + 1) % max_particle_count;
    return result;
}

fn getNextFallingBlockIndex(t: *Tetris) usize {
    const result = t.next_falling_block_index;
    t.next_falling_block_index = (t.next_falling_block_index + 1) % max_falling_block_count;
    return result;
}

fn addExplosion(t: *Tetris, color: Vec4, center_x: f32, center_y: f32) void {
    const particle_count = 12;
    const particle_size = f32(cell_size) / 3.0;
    {
        var i: i32 = 0;
        while (i < particle_count) : (i += 1) {
            const off_x = t.rand.float(f32) * f32(cell_size) / 2.0;
            const off_y = t.rand.float(f32) * f32(cell_size) / 2.0;
            const pos = vec3(center_x + off_x, center_y + off_y, 0.0);
            t.particles[getNextParticleIndex(t)] = createParticle(t, color, particle_size, pos);
        }
    }
}

fn createParticle(t: *Tetris, color: Vec4, size: f32, pos: Vec3) Particle {
    var p: Particle = undefined;

    p.angle_vel = t.rand.float(f32) * 0.1 - 0.05;
    p.angle = t.rand.float(f32) * 2.0 * PI;
    p.axis = vec3(0.0, 0.0, 1.0);
    p.scale_w = size * (0.8 + t.rand.float(f32) * 0.4);
    p.scale_h = size * (0.8 + t.rand.float(f32) * 0.4);
    p.color = color;
    p.pos = pos;

    const vel_x = t.rand.float(f32) * 2.0 - 1.0;
    const vel_y = -(2.0 + t.rand.float(f32) * 1.0);
    p.vel = vec3(vel_x, vel_y, 0.0);

    return p;
}

fn createBlockParticle(t: *Tetris, color: Vec4, pos: Vec3) Particle {
    var p: Particle = undefined;

    p.angle_vel = t.rand.float(f32) * 0.05 - 0.025;
    p.angle = 0;
    p.axis = vec3(0.0, 0.0, 1.0);
    p.scale_w = cell_size;
    p.scale_h = cell_size;
    p.color = color;
    p.pos = pos;

    const vel_x = t.rand.float(f32) * 0.5 - 0.25;
    const vel_y = -t.rand.float(f32) * 0.5;
    p.vel = vec3(vel_x, vel_y, 0.0);

    return p;
}

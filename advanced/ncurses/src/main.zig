pub fn main() !void {
    _ = ncurses.initscr();
    defer _ = ncurses.endwin();
    _ = ncurses.cbreak();
    _ = ncurses.noecho();
    _ = ncurses.keypad(ncurses.stdscr, true);
    _ = ncurses.nodelay(ncurses.stdscr, true);
    _ = ncurses.curs_set(0);
    _ = ncurses.start_color();
    _ = ncurses.init_pair(0, ncurses.COLOR_BLACK, ncurses.COLOR_BLACK);
    _ = ncurses.init_pair(1, ncurses.COLOR_BLACK, ncurses.COLOR_BLUE);
    _ = ncurses.init_pair(2, ncurses.COLOR_BLACK, ncurses.COLOR_GREEN);
    _ = ncurses.init_pair(3, ncurses.COLOR_BLACK, ncurses.COLOR_YELLOW);
    _ = ncurses.init_pair(4, ncurses.COLOR_BLACK, ncurses.COLOR_RED);
    _ = ncurses.init_pair(5, ncurses.COLOR_BLACK, ncurses.COLOR_MAGENTA);
    _ = ncurses.init_pair(6, ncurses.COLOR_BLACK, ncurses.COLOR_CYAN);
    _ = ncurses.init_pair(7, ncurses.COLOR_BLACK, ncurses.COLOR_WHITE);

    const t = &tetris_state;

    limits = nearestTextel([]i32{ window_width - 1, window_height - 1 });
    if (limits[0] >= ncurses.COLS or limits[1] >= ncurses.LINES) {
        return error.ScreenTooSmall;
    }
    t.framebuffer_width = window_width;
    t.framebuffer_height = window_height;

    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    try std.crypto.randomBytes(&seed_bytes);
    t.prng = std.rand.DefaultPrng.init(std.mem.readIntNative(u64, &seed_bytes));
    t.rand = &t.prng.random;

    resetProjection(t);

    restartGame(t);

    const start_time = time.milliTimestamp();
    var prev_time = start_time;

    while (true) {
        const now_time = time.milliTimestamp();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        nextFrame(t, @intToFloat(f64, elapsed) / 1000.0);

        draw(t, @This());

        var key = ncurses.getch();
        if (key != ncurses.ERR) {
            switch(key) {
                27, 'q' => return,
                ' ' => userDropCurPiece(t),
                ncurses.KEY_DOWN, 'z' => userCurPieceFall(t),
                ncurses.KEY_LEFT, 'a' => userMoveCurPiece(t, -1),
                ncurses.KEY_RIGHT, 's' => userMoveCurPiece(t, 1),
                ncurses.KEY_UP, 'w' => userRotateCurPiece(t, 1),
                //c.GLFW_KEY_LEFT_SHIFT, c.GLFW_KEY_RIGHT_SHIFT
                'W'  => userRotateCurPiece(t, -1),
                'r' => restartGame(t),
                'p' => userTogglePause(t),
                //c.GLFW_KEY_LEFT_CONTROL, c.GLFW_KEY_RIGHT_CONTROL
                'h' => userSetHoldPiece(t),
                else => {},
            }
        }
        time.sleep(10 * 1000 * 1000);
    }
}

fn colorPair(color: Vec4) i32 {
    var pair: i32 = 0;
    for(color.data) |component, i| {
        if (i < 3) {
            pair = pair << 1 | (if (component >= 0.5) @intCast(i32, 1) else 0);
        }
    }
    return pair;
}

fn apply(mvp: Mat4x4, vertex: [2]f32) [2]f32 {
    return []f32{ 
        mvp.data[0][0] * vertex[0] + mvp.data[0][1] * vertex[1] + mvp.data[0][3],
        mvp.data[1][0] * vertex[0] + mvp.data[1][1] * vertex[1] + mvp.data[1][3],
    };
}

fn nearestPixel(fraction: [2]f32, t: *Tetris) [2]i32 {
    return []i32{
        @floatToInt(i32, fraction[0] * @intToFloat(f32, t.framebuffer_width)),
        @floatToInt(i32, fraction[1] * @intToFloat(f32, t.framebuffer_height)),
    };
}

fn nearestTextel(vertex: [2]i32) [2]i32 {
    const aspect_ratio: i32 = 2;
    return []i32{
        @divTrunc(vertex[0], cell_size) * aspect_ratio,
        @divTrunc(vertex[1], cell_size),
    };
}

const rect_2d_vertices = [][2]f32{
    []f32{ 0.0, 0.0 },
    []f32{ 0.0, 1.0 },
    []f32{ 1.0, 0.0 },
    []f32{ 1.0, 1.0 },
};

pub fn fillRectMvp(t: *Tetris, color: Vec4, mvp: Mat4x4) void {
    var four_corners: [4][2]i32 = undefined;
    for (rect_2d_vertices) |vertex, i| {
        const applied = apply(mvp, vertex);
        const mapped = []f32{ (applied[0] + 1.0) / 2.0, -(applied[1] - 1.0) / 2.0 };
        four_corners[i] = nearestTextel(nearestPixel(mapped, t));
    }
    const top_left = four_corners[0];
    const bottom_right = four_corners[3];
    const color_pair = colorPair(color);
    const opacity = color.data[3];
    const symbol = if (opacity < 1.0) @intCast(u8, '?') else ' ';
    _ = ncurses.attron(ncurses.COLOR_PAIR(color_pair));
    defer _ = ncurses.attroff(ncurses.COLOR_PAIR(color_pair));
    var x = top_left[0];
    while (x < bottom_right[0] and x < limits[0]) : (x += 1) {
        var y = top_left[1];
        while (y < bottom_right[1] and y < limits[1]) : (y += 1) {
            _ = ncurses.mvaddch(y, x, symbol);
        }
    }
}

pub fn drawParticle(t: *Tetris, p: Particle) void {
    const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);
    const mvp = t.projection.mult(model);
    fillRectMvp(t, p.color, mvp);
}

var draw_text_buf = std.Buffer.initNull(heap);
pub fn drawText(t: *Tetris, text: []const u8, left: i32, top: i32, size: f32) void {
    draw_text_buf.replaceContents(text) catch unreachable;
    const nearest = nearestTextel([]i32{ left, top });
    _ = ncurses.mvaddstr(nearest[1], nearest[0], draw_text_buf.toSlice().ptr);
}

var tetris_state: Tetris = undefined;
var limits: [2]i32 = undefined;

use @import("repo.symlink/src/tetris.zig");
use @import("repo.symlink/src/math3d.zig");
const ncurses = @cImport({
    @cInclude("ncurses.h");
});
const std = @import("std");
const time = std.time;
const heap = std.heap.c_allocator;

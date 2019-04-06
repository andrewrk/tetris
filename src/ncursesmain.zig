use @import("math3d.zig");

const c = @import("c.zig");
const std = @import("std");
const tetris = @import("tetris.zig");

const ncurses = @cImport({
    @cInclude("ncurses.h");
});

const assert = std.debug.assert;
const bufPrint = std.fmt.bufPrint;
const os = std.os;
const panic = std.debug.panic;

const NcursesTetris = struct {
    base: tetris.Tetris,
};

pub fn main() void {
    var tetris_state: NcursesTetris = undefined;
    const t = &tetris_state;

    _ = ncurses.initscr();
    defer _ = ncurses.endwin();

    _ = ncurses.start_color();
    _ = ncurses.init_pair(1, ncurses.COLOR_BLACK, ncurses.COLOR_WHITE);
    _ = ncurses.init_pair(2, ncurses.COLOR_BLACK, ncurses.COLOR_BLUE);
    _ = ncurses.cbreak();
    _ = ncurses.noecho();
    _ = ncurses.nodelay(ncurses.stdscr, true);

    t.base.framebuffer_width = tetris.window_width;
    t.base.framebuffer_height = tetris.window_height;
    
    assert(t.base.framebuffer_width >= tetris.window_width);
    assert(t.base.framebuffer_height >= tetris.window_height);

    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    os.getRandomBytes(seed_bytes[0..]) catch |err| {
        panic("unable to seed random number generator: {}", err);
    };
    t.base.prng = std.rand.DefaultPrng.init(0); //std.mem.readIntNative(u64, &seed_bytes));
    t.base.rand = &t.base.prng.random;

    t.base.resetProjection();

    t.base.restartGame();

    const start_time = os.time.milliTimestamp();
    var prev_time = start_time;

    while (true) {
        const now_time = os.time.milliTimestamp();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        t.base.nextFrame(@intToFloat(f32, elapsed) / 1000.0);

        _ = ncurses.erase();
        t.base.draw(@ptrCast(*u64, t), drawParticlePixels, drawRectanglePixels, drawTextPixels);
        _ = ncurses.refresh();

        var key = ncurses.getch();
        if (key != ncurses.ERR) {
            switch (key) {
                27, 'q' => return,
                ' ' => t.base.userDropCurPiece(),
                'z' => t.base.userCurPieceFall(),
                'a' => t.base.userMoveCurPiece(-1),
                's' => t.base.userMoveCurPiece(1),
                'w' => t.base.userRotateCurPiece(1),
                'W' => t.base.userRotateCurPiece(-1),
                'r' => t.base.restartGame(),
                'p' => t.base.userTogglePause(),
                'h' => t.base.userSetHoldPiece(),
                else => {},
            }
        }
    }
}

fn drawParticlePixels(callback_user_pointer: *u64, p: tetris.Particle) void {
    const t = @ptrCast(*NcursesTetris, callback_user_pointer);
//  const model = mat4x4_identity.translateByVec(p.pos).rotate(p.angle, p.axis).scale(p.scale_w, p.scale_h, 0.0);
    const model = mat4x4_identity.translateByVec(p.pos).scale(p.scale_w, p.scale_h, 0.0);
    const mvp = t.base.projection.mult(model);
//  c.glBindBuffer(c.GL_ARRAY_BUFFER, t.static_geometry.triangle_2d_vertex_buffer);
}

inline fn xToColumn(t: *NcursesTetris, mvp: Mat4x4, x: f32) c_int {
    const applied = mvp.data[0][0] * x + mvp.data[0][3];
    const relocated = @intToFloat(f32, t.base.framebuffer_width) / 2.0 * (applied + 1.0);
    return @divTrunc(@floatToInt(c_int, relocated), tetris.font_char_width);
}

inline fn yToRow(t: *NcursesTetris, mvp: Mat4x4, y: f32) c_int {
    const applied = mvp.data[1][1] * y + mvp.data[1][3];
    const relocated = @intToFloat(f32, t.base.framebuffer_height) / 2.0 * (-applied + 1.0);
    return @divTrunc(@floatToInt(c_int, relocated), tetris.font_char_height);
}

fn isGray(color: Vec4) bool {
    var gray = true;
    for (color.data[0..3]) |component| {
        gray = gray and @floatToInt(i32, component * 255.0) == 72;
    }
    return gray;
}

fn drawRectanglePixels(callback_user_pointer: *u64, color: Vec4, mvp: Mat4x4) void {
    const t = @ptrCast(*NcursesTetris, callback_user_pointer);

    var color_pair_number: i32 = undefined;
    if (isGray(color)) {
        color_pair_number = 1;
    } else {
        color_pair_number = 2;
    }
    const color_pair = ncurses.COLOR_PAIR(color_pair_number);
    _ = ncurses.attron(color_pair);
    defer _ = ncurses.attroff(color_pair);

    var symbol: u8 = ' ';
    if (color.data[3] < 1.0) {
        symbol = '?';
    }

    if (mvp.data[0][1] != 0.0 or mvp.data[0][2] != 0.0 or mvp.data[1][0] != 0.0 or mvp.data[1][2] != 0.0) {
        panic("unexpected mvp matrix");
    }
    var col = xToColumn(t, mvp, 0.0);
    const last_col = xToColumn(t, mvp, 1.0) - 1;
    const first_row = yToRow(t, mvp, 0.0);
    const last_row = yToRow(t, mvp, 1.0) - 1;
    while (col <= last_col) : (col += 1) {
        var row = first_row;
        while (row <= last_row) : (row += 1) {
            _ = ncurses.mvaddch(row, col, symbol);
        }
    }
}

fn drawTextPixels(callback_user_pointer: *u64, text: []const u8, left: i32, top: i32, size: f32) void {
    const t = @ptrCast(*NcursesTetris, callback_user_pointer);
    var textBuf: [100]u8 = undefined;
    textBuf[0] = 0;
    _ = bufPrint(textBuf[0..], "{}\x00", text) catch unreachable;
    _ = ncurses.mvaddstr(@divTrunc(top, tetris.font_char_height), @divTrunc(left, tetris.font_char_width), textBuf[0..].ptr);
}

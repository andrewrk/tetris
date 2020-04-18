const Vec4 = @import("math3d.zig").Vec4;

pub const Piece = struct {
    name: u8,
    color: Vec4,
    layout: [4][4][4]bool,
};

const F = false;
const T = true;

pub const pieces = [_]Piece{
    Piece{
        .name = 'I',
        .color = Vec4{
            .data = [_]f32{ 0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'O',
        .color = Vec4{
            .data = [_]f32{ 255.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
        },
    },
    Piece{
        .name = 'T',
        .color = Vec4{
            .data = [_]f32{ 255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'J',
        .color = Vec4{
            .data = [_]f32{ 0.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, T, F },
            },
        },
    },
    Piece{
        .name = 'L',
        .color = Vec4{
            .data = [_]f32{ 255.0 / 255.0, 128.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ T, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
        },
    },
    Piece{
        .name = 'S',
        .color = Vec4{
            .data = [_]f32{ 0.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'Z',
        .color = Vec4{
            .data = [_]f32{ 255.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
};

const Vec4 = @import("math3d.zig").Vec4;

pub const Piece = struct {
    name: u8,
    color: Vec4,
    layout: [4][4][4]bool,
};

const F = false;
const T = true;

pub const pieces = []Piece{
    Piece{
        .name = 'I',
        .color = Vec4{
            .data = []f32{ 0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, T, T },
                []bool{ F, F, F, F },
            },
            [][4]bool{
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, T, T },
                []bool{ F, F, F, F },
            },
            [][4]bool{
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'T',
        .color = Vec4{
            .data = []f32{ 255.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ T, T, F, F },
            },
        },
    },
    Piece{
        .name = 'T',
        .color = Vec4{
            .data = []f32{ 255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, T, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, F, F },
                []bool{ T, T, T, F },
                []bool{ F, F, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, T, F },
                []bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'J',
        .color = Vec4{
            .data = []f32{ 0.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ T, F, F, F },
                []bool{ T, T, T, F },
                []bool{ F, F, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, T, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, T, F },
                []bool{ F, F, T, F },
            },
        },
    },
    Piece{
        .name = 'L',
        .color = Vec4{
            .data = []f32{ 255.0 / 255.0, 128.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, T, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, T, F },
                []bool{ T, F, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, F, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, T, F },
                []bool{ T, T, T, F },
                []bool{ F, F, F, F },
            },
        },
    },
    Piece{
        .name = 'S',
        .color = Vec4{
            .data = []f32{ 0.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ F, T, T, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ T, F, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ F, T, T, F },
                []bool{ T, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ T, F, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'Z',
        .color = Vec4{
            .data = []f32{ 255.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0 },
        },
        .layout = [][4][4]bool{
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, T, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, T, F },
                []bool{ F, T, T, F },
                []bool{ F, T, F, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, F, F },
                []bool{ T, T, F, F },
                []bool{ F, T, T, F },
            },
            [][4]bool{
                []bool{ F, F, F, F },
                []bool{ F, F, T, F },
                []bool{ F, T, T, F },
                []bool{ F, T, F, F },
            },
        },
    },
};

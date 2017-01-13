const Vec4 = @import("math3d.zig").Vec4;

pub const Piece = struct {
    name: u8,
    color: Vec4,
    layout: [4][4][4]bool,
};

const _ = false;
const O = true;

pub const pieces = []Piece {
    Piece {
        .name = 'I',
        .color = Vec4 { .data = []f32{ 0.0/255.0, 255.0/255.0, 255.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, O, O },
                []bool{ _, _, _, _ },
            },
            [][4]bool {
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, O, O },
                []bool{ _, _, _, _ },
            },
            [][4]bool {
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
            },
        },
    },
    Piece {
        .name = 'O',
        .color = Vec4 { .data = []f32{ 255.0/255.0, 255.0/255.0, 0.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ O, O, _, _ },
            },
        },
    },
    Piece {
        .name = 'T',
        .color = Vec4 { .data = []f32{ 255.0/255.0, 0.0/255.0, 255.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, O, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, _, _ },
                []bool{ O, O, O, _ },
                []bool{ _, _, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, O, _ },
                []bool{ _, O, _, _ },
            },
        },
    },
    Piece {
        .name = 'J',
        .color = Vec4 { .data = []f32{ 0.0/255.0, 0.0/255.0, 255.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ O, _, _, _ },
                []bool{ O, O, O, _ },
                []bool{ _, _, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, O, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, O, _ },
                []bool{ _, _, O, _ },
            },
        },
    },
    Piece {
        .name = 'L',
        .color = Vec4 { .data = []f32{ 255.0/255.0, 128.0/255.0, 0.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, O, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, O, _ },
                []bool{ O, _, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, _, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, O, _ },
                []bool{ O, O, O, _ },
                []bool{ _, _, _, _ },
            },
        },
    },
    Piece {
        .name = 'S',
        .color = Vec4 { .data = []f32{ 0.0/255.0, 255.0/255.0, 0.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ _, O, O, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ O, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ _, O, O, _ },
                []bool{ O, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ O, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, _, _ },
            },
        },
    },
    Piece {
        .name = 'Z',
        .color = Vec4 { .data = []f32{ 255.0/255.0, 0.0/255.0, 0.0/255.0, 1.0 }, },
        .layout = [][4][4]bool {
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, O, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, O, _ },
                []bool{ _, O, O, _ },
                []bool{ _, O, _, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, _, _ },
                []bool{ O, O, _, _ },
                []bool{ _, O, O, _ },
            },
            [][4]bool {
                []bool{ _, _, _, _ },
                []bool{ _, _, O, _ },
                []bool{ _, O, O, _ },
                []bool{ _, O, _, _ },
            },
        },
    },
};


const std = @import("std");
const assert = std.debug.assert;
const c = @import("c.zig");

pub const Mat4x4 = struct {
    data: [4][4]f32,

    pub const identity = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 1.0, 0.0, 0.0, 0.0 },
            [_]f32{ 0.0, 1.0, 0.0, 0.0 },
            [_]f32{ 0.0, 0.0, 1.0, 0.0 },
            [_]f32{ 0.0, 0.0, 0.0, 1.0 },
        },
    };

    /// matrix multiplication
    pub fn mult(m: Mat4x4, other: Mat4x4) Mat4x4 {
        return Mat4x4{
            .data = [_][4]f32{
                [_]f32{
                    m.data[0][0] * other.data[0][0] + m.data[0][1] * other.data[1][0] + m.data[0][2] * other.data[2][0] + m.data[0][3] * other.data[3][0],
                    m.data[0][0] * other.data[0][1] + m.data[0][1] * other.data[1][1] + m.data[0][2] * other.data[2][1] + m.data[0][3] * other.data[3][1],
                    m.data[0][0] * other.data[0][2] + m.data[0][1] * other.data[1][2] + m.data[0][2] * other.data[2][2] + m.data[0][3] * other.data[3][2],
                    m.data[0][0] * other.data[0][3] + m.data[0][1] * other.data[1][3] + m.data[0][2] * other.data[2][3] + m.data[0][3] * other.data[3][3],
                },
                [_]f32{
                    m.data[1][0] * other.data[0][0] + m.data[1][1] * other.data[1][0] + m.data[1][2] * other.data[2][0] + m.data[1][3] * other.data[3][0],
                    m.data[1][0] * other.data[0][1] + m.data[1][1] * other.data[1][1] + m.data[1][2] * other.data[2][1] + m.data[1][3] * other.data[3][1],
                    m.data[1][0] * other.data[0][2] + m.data[1][1] * other.data[1][2] + m.data[1][2] * other.data[2][2] + m.data[1][3] * other.data[3][2],
                    m.data[1][0] * other.data[0][3] + m.data[1][1] * other.data[1][3] + m.data[1][2] * other.data[2][3] + m.data[1][3] * other.data[3][3],
                },
                [_]f32{
                    m.data[2][0] * other.data[0][0] + m.data[2][1] * other.data[1][0] + m.data[2][2] * other.data[2][0] + m.data[2][3] * other.data[3][0],
                    m.data[2][0] * other.data[0][1] + m.data[2][1] * other.data[1][1] + m.data[2][2] * other.data[2][1] + m.data[2][3] * other.data[3][1],
                    m.data[2][0] * other.data[0][2] + m.data[2][1] * other.data[1][2] + m.data[2][2] * other.data[2][2] + m.data[2][3] * other.data[3][2],
                    m.data[2][0] * other.data[0][3] + m.data[2][1] * other.data[1][3] + m.data[2][2] * other.data[2][3] + m.data[2][3] * other.data[3][3],
                },
                [_]f32{
                    m.data[3][0] * other.data[0][0] + m.data[3][1] * other.data[1][0] + m.data[3][2] * other.data[2][0] + m.data[3][3] * other.data[3][0],
                    m.data[3][0] * other.data[0][1] + m.data[3][1] * other.data[1][1] + m.data[3][2] * other.data[2][1] + m.data[3][3] * other.data[3][1],
                    m.data[3][0] * other.data[0][2] + m.data[3][1] * other.data[1][2] + m.data[3][2] * other.data[2][2] + m.data[3][3] * other.data[3][2],
                    m.data[3][0] * other.data[0][3] + m.data[3][1] * other.data[1][3] + m.data[3][2] * other.data[2][3] + m.data[3][3] * other.data[3][3],
                },
            },
        };
    }

    /// Builds a rotation 4 * 4 matrix created from an axis vector and an angle.
    /// Input matrix multiplied by this rotation matrix.
    /// angle: Rotation angle expressed in radians.
    /// axis: Rotation axis, recommended to be normalized.
    pub fn rotate(m: Mat4x4, angle: f32, axis_unnormalized: Vec3) Mat4x4 {
        const cos = c.cosf(angle);
        const s = c.sinf(angle);
        const axis = axis_unnormalized.normalize();
        const temp = axis.scale(1.0 - cos);

        const rot = Mat4x4{
            .data = [_][4]f32{
                [_]f32{ cos + temp.data[0] * axis.data[0], 0.0 + temp.data[1] * axis.data[0] - s * axis.data[2], 0.0 + temp.data[2] * axis.data[0] + s * axis.data[1], 0.0 },
                [_]f32{ 0.0 + temp.data[0] * axis.data[1] + s * axis.data[2], cos + temp.data[1] * axis.data[1], 0.0 + temp.data[2] * axis.data[1] - s * axis.data[0], 0.0 },
                [_]f32{ 0.0 + temp.data[0] * axis.data[2] - s * axis.data[1], 0.0 + temp.data[1] * axis.data[2] + s * axis.data[0], cos + temp.data[2] * axis.data[2], 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        };

        return Mat4x4{
            .data = [_][4]f32{
                [_]f32{
                    m.data[0][0] * rot.data[0][0] + m.data[0][1] * rot.data[1][0] + m.data[0][2] * rot.data[2][0],
                    m.data[0][0] * rot.data[0][1] + m.data[0][1] * rot.data[1][1] + m.data[0][2] * rot.data[2][1],
                    m.data[0][0] * rot.data[0][2] + m.data[0][1] * rot.data[1][2] + m.data[0][2] * rot.data[2][2],
                    m.data[0][3],
                },
                [_]f32{
                    m.data[1][0] * rot.data[0][0] + m.data[1][1] * rot.data[1][0] + m.data[1][2] * rot.data[2][0],
                    m.data[1][0] * rot.data[0][1] + m.data[1][1] * rot.data[1][1] + m.data[1][2] * rot.data[2][1],
                    m.data[1][0] * rot.data[0][2] + m.data[1][1] * rot.data[1][2] + m.data[1][2] * rot.data[2][2],
                    m.data[1][3],
                },
                [_]f32{
                    m.data[2][0] * rot.data[0][0] + m.data[2][1] * rot.data[1][0] + m.data[2][2] * rot.data[2][0],
                    m.data[2][0] * rot.data[0][1] + m.data[2][1] * rot.data[1][1] + m.data[2][2] * rot.data[2][1],
                    m.data[2][0] * rot.data[0][2] + m.data[2][1] * rot.data[1][2] + m.data[2][2] * rot.data[2][2],
                    m.data[2][3],
                },
                [_]f32{
                    m.data[3][0] * rot.data[0][0] + m.data[3][1] * rot.data[1][0] + m.data[3][2] * rot.data[2][0],
                    m.data[3][0] * rot.data[0][1] + m.data[3][1] * rot.data[1][1] + m.data[3][2] * rot.data[2][1],
                    m.data[3][0] * rot.data[0][2] + m.data[3][1] * rot.data[1][2] + m.data[3][2] * rot.data[2][2],
                    m.data[3][3],
                },
            },
        };
    }

    /// Builds a translation 4 * 4 matrix created from a vector of 3 components.
    /// Input matrix multiplied by this translation matrix.
    pub fn translate(m: Mat4x4, x: f32, y: f32, z: f32) Mat4x4 {
        return Mat4x4{
            .data = [_][4]f32{
                [_]f32{ m.data[0][0], m.data[0][1], m.data[0][2], m.data[0][3] + m.data[0][0] * x + m.data[0][1] * y + m.data[0][2] * z },
                [_]f32{ m.data[1][0], m.data[1][1], m.data[1][2], m.data[1][3] + m.data[1][0] * x + m.data[1][1] * y + m.data[1][2] * z },
                [_]f32{ m.data[2][0], m.data[2][1], m.data[2][2], m.data[2][3] + m.data[2][0] * x + m.data[2][1] * y + m.data[2][2] * z },
                [_]f32{ m.data[3][0], m.data[3][1], m.data[3][2], m.data[3][3] },
            },
        };
    }

    pub fn translateByVec(m: Mat4x4, v: Vec3) Mat4x4 {
        return m.translate(v.data[0], v.data[1], v.data[2]);
    }

    /// Builds a scale 4 * 4 matrix created from 3 scalars.
    /// Input matrix multiplied by this scale matrix.
    pub fn scale(m: Mat4x4, x: f32, y: f32, z: f32) Mat4x4 {
        return Mat4x4{
            .data = [_][4]f32{
                [_]f32{ m.data[0][0] * x, m.data[0][1] * y, m.data[0][2] * z, m.data[0][3] },
                [_]f32{ m.data[1][0] * x, m.data[1][1] * y, m.data[1][2] * z, m.data[1][3] },
                [_]f32{ m.data[2][0] * x, m.data[2][1] * y, m.data[2][2] * z, m.data[2][3] },
                [_]f32{ m.data[3][0] * x, m.data[3][1] * y, m.data[3][2] * z, m.data[3][3] },
            },
        };
    }

    pub fn transpose(m: Mat4x4) Mat4x4 {
        return Mat4x4{
            .data = [_][4]f32{
                [_]f32{ m.data[0][0], m.data[1][0], m.data[2][0], m.data[3][0] },
                [_]f32{ m.data[0][1], m.data[1][1], m.data[2][1], m.data[3][1] },
                [_]f32{ m.data[0][2], m.data[1][2], m.data[2][2], m.data[3][2] },
                [_]f32{ m.data[0][3], m.data[1][3], m.data[2][3], m.data[3][3] },
            },
        };
    }

    /// Creates a matrix for an orthographic parallel viewing volume.
    pub fn ortho(left: f32, right: f32, bottom: f32, top: f32) Mat4x4 {
        var m = identity;
        m.data[0][0] = 2.0 / (right - left);
        m.data[1][1] = 2.0 / (top - bottom);
        m.data[2][2] = -1.0;
        m.data[0][3] = -(right + left) / (right - left);
        m.data[1][3] = -(top + bottom) / (top - bottom);
        return m;
    }
};

pub const Vec3 = struct {
    data: [3]f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .data = [_]f32{ x, y, z },
        };
    }

    pub fn normalize(v: Vec3) Vec3 {
        return v.scale(1.0 / c.sqrtf(v.dot(v)));
    }

    pub fn scale(v: Vec3, scalar: f32) Vec3 {
        return Vec3{
            .data = [_]f32{
                v.data[0] * scalar,
                v.data[1] * scalar,
                v.data[2] * scalar,
            },
        };
    }

    pub fn dot(v: Vec3, other: Vec3) f32 {
        return v.data[0] * other.data[0] +
            v.data[1] * other.data[1] +
            v.data[2] * other.data[2];
    }

    pub fn length(v: Vec3) f32 {
        return c.sqrtf(v.dot(v));
    }

    /// returns the cross product
    pub fn cross(v: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .data = [_]f32{
                v.data[1] * other.data[2] - other.data[1] * v.data[2],
                v.data[2] * other.data[0] - other.data[2] * v.data[0],
                v.data[0] * other.data[1] - other.data[0] * v.data[1],
            },
        };
    }

    pub fn add(v: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .data = [_]f32{
                v.data[0] + other.data[0],
                v.data[1] + other.data[1],
                v.data[2] + other.data[2],
            },
        };
    }
};

pub const Vec4 = struct {
    data: [4]f32,

    pub fn init(xa: f32, xb: f32, xc: f32, xd: f32) Vec4 {
        return Vec4{
            .data = [_]f32{ xa, xb, xc, xd },
        };
    }
};

test "scale" {
    const m = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.840188, 0.911647, 0.277775, 0.364784 },
            [_]f32{ 0.394383, 0.197551, 0.55397, 0.513401 },
            [_]f32{ 0.783099, 0.335223, 0.477397, 0.95223 },
            [_]f32{ 0.79844, 0.76823, 0.628871, 0.916195 },
        },
    };
    const expected = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.118973, 0.653922, 0.176585, 0.364784 },
            [_]f32{ 0.0558456, 0.141703, 0.352165, 0.513401 },
            [_]f32{ 0.110889, 0.240454, 0.303487, 0.95223 },
            [_]f32{ 0.113061, 0.551049, 0.399781, 0.916195 },
        },
    };
    const answer = m.scale(0.141603, 0.717297, 0.635712);
    assert_matrix_eq(answer, expected);
}

test "translate" {
    const m = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.840188, 0.911647, 0.277775, 0.364784 },
            [_]f32{ 0.394383, 0.197551, 0.55397, 0.513401 },
            [_]f32{ 0.783099, 0.335223, 0.477397, 0.95223 },
            [_]f32{ 0.79844, 0.76823, 0.628871, 1.0 },
        },
    };
    const expected = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.840188, 0.911647, 0.277775, 1.31426 },
            [_]f32{ 0.394383, 0.197551, 0.55397, 1.06311 },
            [_]f32{ 0.783099, 0.335223, 0.477397, 1.60706 },
            [_]f32{ 0.79844, 0.76823, 0.628871, 1.0 },
        },
    };
    const answer = m.translate(0.141603, 0.717297, 0.635712);
    assert_matrix_eq(answer, expected);
}

test "ortho" {
    const m = Mat4x4.ortho(0.840188, 0.394383, 0.783099, 0.79844);

    const expected = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ -4.48627, 0.0, 0.0, 2.76931 },
            [_]f32{ 0.0, 130.371, 0.0, -103.094 },
            [_]f32{ 0.0, 0.0, -1.0, 0.0 },
            [_]f32{ 0.0, 0.0, 0.0, 1.0 },
        },
    };

    assert_matrix_eq(m, expected);
}

fn assert_f_eq(left: f32, right: f32) void {
    const diff = c.fabsf(left - right);
    assert(diff < 0.01);
}

fn assert_matrix_eq(left: Mat4x4, right: Mat4x4) void {
    assert_f_eq(left.data[0][0], right.data[0][0]);
    assert_f_eq(left.data[0][1], right.data[0][1]);
    assert_f_eq(left.data[0][2], right.data[0][2]);
    assert_f_eq(left.data[0][3], right.data[0][3]);

    assert_f_eq(left.data[1][0], right.data[1][0]);
    assert_f_eq(left.data[1][1], right.data[1][1]);
    assert_f_eq(left.data[1][2], right.data[1][2]);
    assert_f_eq(left.data[1][3], right.data[1][3]);

    assert_f_eq(left.data[2][0], right.data[2][0]);
    assert_f_eq(left.data[2][1], right.data[2][1]);
    assert_f_eq(left.data[2][2], right.data[2][2]);
    assert_f_eq(left.data[2][3], right.data[2][3]);

    assert_f_eq(left.data[3][0], right.data[3][0]);
    assert_f_eq(left.data[3][1], right.data[3][1]);
    assert_f_eq(left.data[3][2], right.data[3][2]);
    assert_f_eq(left.data[3][3], right.data[3][3]);
}

test "mult" {
    const m1 = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.635712, 0.717297, 0.141603, 0.606969 },
            [_]f32{ 0.0163006, 0.242887, 0.137232, 0.804177 },
            [_]f32{ 0.156679, 0.400944, 0.12979, 0.108809 },
            [_]f32{ 0.998924, 0.218257, 0.512932, 0.839112 },
        },
    };
    const m2 = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.840188, 0.394383, 0.783099, 0.79844 },
            [_]f32{ 0.911647, 0.197551, 0.335223, 0.76823 },
            [_]f32{ 0.277775, 0.55397, 0.477397, 0.628871 },
            [_]f32{ 0.364784, 0.513401, 0.95223, 0.916195 },
        },
    };
    const answer = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 1.44879, 0.782479, 1.38385, 1.70378 },
            [_]f32{ 0.566593, 0.543299, 0.925461, 1.02269 },
            [_]f32{ 0.572904, 0.268761, 0.422673, 0.614428 },
            [_]f32{ 1.48683, 1.15203, 1.89932, 2.05661 },
        },
    };
    const tmp = m1.mult(m2);
    assert_matrix_eq(tmp, answer);
}

test "rotate" {
    const m1 = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 0.840188, 0.911647, 0.277775, 0.364784 },
            [_]f32{ 0.394383, 0.197551, 0.55397, 0.513401 },
            [_]f32{ 0.783099, 0.335223, 0.477397, 0.95223 },
            [_]f32{ 0.79844, 0.76823, 0.628871, 0.916195 },
        },
    };
    const angle = 0.635712;

    const axis = Vec3.init(0.606969, 0.141603, 0.717297);

    const expected = Mat4x4{
        .data = [_][4]f32{
            [_]f32{ 1.17015, 0.488019, 0.0821911, 0.364784 },
            [_]f32{ 0.444151, 0.212659, 0.508874, 0.513401 },
            [_]f32{ 0.851739, 0.126319, 0.460555, 0.95223 },
            [_]f32{ 1.06829, 0.530801, 0.447396, 0.916195 },
        },
    };

    const actual = m1.rotate(angle, axis);
    assert_matrix_eq(actual, expected);
}

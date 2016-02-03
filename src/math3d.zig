import "libc.zig";

pub struct Mat4x4 {
    data: [4][4]f32,

    /// matrix multiplication
    pub fn mult(m: Mat4x4, other: Mat4x4) -> Mat4x4 {
        Mat4x4 {
            .data = [][4]f32{
                []f32{
                    m.data[0][0]*other.data[0][0] + m.data[0][1]*other.data[1][0] + m.data[0][2]*other.data[2][0] + m.data[0][3]*other.data[3][0],
                    m.data[0][0]*other.data[0][1] + m.data[0][1]*other.data[1][1] + m.data[0][2]*other.data[2][1] + m.data[0][3]*other.data[3][1],
                    m.data[0][0]*other.data[0][2] + m.data[0][1]*other.data[1][2] + m.data[0][2]*other.data[2][2] + m.data[0][3]*other.data[3][2],
                    m.data[0][0]*other.data[0][3] + m.data[0][1]*other.data[1][3] + m.data[0][2]*other.data[2][3] + m.data[0][3]*other.data[3][3],
                },
                []f32{
                    m.data[1][0]*other.data[0][0] + m.data[1][1]*other.data[1][0] + m.data[1][2]*other.data[2][0] + m.data[1][3]*other.data[3][0],
                    m.data[1][0]*other.data[0][1] + m.data[1][1]*other.data[1][1] + m.data[1][2]*other.data[2][1] + m.data[1][3]*other.data[3][1],
                    m.data[1][0]*other.data[0][2] + m.data[1][1]*other.data[1][2] + m.data[1][2]*other.data[2][2] + m.data[1][3]*other.data[3][2],
                    m.data[1][0]*other.data[0][3] + m.data[1][1]*other.data[1][3] + m.data[1][2]*other.data[2][3] + m.data[1][3]*other.data[3][3],
                },
                []f32{
                    m.data[2][0]*other.data[0][0] + m.data[2][1]*other.data[1][0] + m.data[2][2]*other.data[2][0] + m.data[2][3]*other.data[3][0],
                    m.data[2][0]*other.data[0][1] + m.data[2][1]*other.data[1][1] + m.data[2][2]*other.data[2][1] + m.data[2][3]*other.data[3][1],
                    m.data[2][0]*other.data[0][2] + m.data[2][1]*other.data[1][2] + m.data[2][2]*other.data[2][2] + m.data[2][3]*other.data[3][2],
                    m.data[2][0]*other.data[0][3] + m.data[2][1]*other.data[1][3] + m.data[2][2]*other.data[2][3] + m.data[2][3]*other.data[3][3],
                },
                []f32{
                    m.data[3][0]*other.data[0][0] + m.data[3][1]*other.data[1][0] + m.data[3][2]*other.data[2][0] + m.data[3][3]*other.data[3][0],
                    m.data[3][0]*other.data[0][1] + m.data[3][1]*other.data[1][1] + m.data[3][2]*other.data[2][1] + m.data[3][3]*other.data[3][1],
                    m.data[3][0]*other.data[0][2] + m.data[3][1]*other.data[1][2] + m.data[3][2]*other.data[2][2] + m.data[3][3]*other.data[3][2],
                    m.data[3][0]*other.data[0][3] + m.data[3][1]*other.data[1][3] + m.data[3][2]*other.data[2][3] + m.data[3][3]*other.data[3][3],
                },
            },
        }
    }

    /// Builds a rotation 4 * 4 matrix created from an axis vector and an angle.
    /// Input matrix multiplied by this rotation matrix.
    /// angle: Rotation angle expressed in radians.
    /// axis: Rotation axis, recommended to be normalized.
    pub fn rotate(m: Mat4x4, angle: f32, axis_unnormalized: Vec3) -> Mat4x4 {
        const c = cosf(angle);
        const s = sinf(angle);
        const axis = axis_unnormalized.normalize();
        const temp = axis.scale(1.0 - c);

        const rotate = Mat4x4 {
            .data = [][4]f32 {
                []f32{c   + temp.data[0] * axis.data[0],                    0.0 + temp.data[1] * axis.data[0] - s * axis.data[2], 0.0 + temp.data[2] * axis.data[0] + s * axis.data[1], 0.0},
                []f32{0.0 + temp.data[0] * axis.data[1] + s * axis.data[2], c   + temp.data[1] * axis.data[1],                    0.0 + temp.data[2] * axis.data[1] - s * axis.data[0], 0.0},
                []f32{0.0 + temp.data[0] * axis.data[2] - s * axis.data[1], 0.0 + temp.data[1] * axis.data[2] + s * axis.data[0], c   + temp.data[2] * axis.data[2], 0.0},
                []f32{0.0, 0.0, 0.0, 0.0},
            },
        };

        Mat4x4 {
            .data = [][4]f32 {
                []f32 {
                    m.data[0][0] * rotate.data[0][0] + m.data[0][1] * rotate.data[1][0] + m.data[0][2] * rotate.data[2][0],
                    m.data[0][0] * rotate.data[0][1] + m.data[0][1] * rotate.data[1][1] + m.data[0][2] * rotate.data[2][1],
                    m.data[0][0] * rotate.data[0][2] + m.data[0][1] * rotate.data[1][2] + m.data[0][2] * rotate.data[2][2],
                    m.data[0][3]
                },
                []f32 {
                    m.data[1][0] * rotate.data[0][0] + m.data[1][1] * rotate.data[1][0] + m.data[1][2] * rotate.data[2][0],
                    m.data[1][0] * rotate.data[0][1] + m.data[1][1] * rotate.data[1][1] + m.data[1][2] * rotate.data[2][1],
                    m.data[1][0] * rotate.data[0][2] + m.data[1][1] * rotate.data[1][2] + m.data[1][2] * rotate.data[2][2],
                    m.data[1][3]
                },
                []f32 {
                    m.data[2][0] * rotate.data[0][0] + m.data[2][1] * rotate.data[1][0] + m.data[2][2] * rotate.data[2][0],
                    m.data[2][0] * rotate.data[0][1] + m.data[2][1] * rotate.data[1][1] + m.data[2][2] * rotate.data[2][1],
                    m.data[2][0] * rotate.data[0][2] + m.data[2][1] * rotate.data[1][2] + m.data[2][2] * rotate.data[2][2],
                    m.data[2][3]
                },
                []f32 {
                    m.data[3][0] * rotate.data[0][0] + m.data[3][1] * rotate.data[1][0] + m.data[3][2] * rotate.data[2][0],
                    m.data[3][0] * rotate.data[0][1] + m.data[3][1] * rotate.data[1][1] + m.data[3][2] * rotate.data[2][1],
                    m.data[3][0] * rotate.data[0][2] + m.data[3][1] * rotate.data[1][2] + m.data[3][2] * rotate.data[2][2],
                    m.data[3][3]
                },
            },
        }
    }

    /// Builds a translation 4 * 4 matrix created from a vector of 3 components.
    /// Input matrix multiplied by this translation matrix.
    pub fn translate(m: Mat4x4, x: f32, y: f32, z: f32) -> Mat4x4 {
        Mat4x4 {
            .data = [][4]f32 {
                []f32{m.data[0][0], m.data[0][1], m.data[0][2], m.data[0][3] + m.data[0][0] * x + m.data[0][1] * y + m.data[0][2] * z},
                []f32{m.data[1][0], m.data[1][1], m.data[1][2], m.data[1][3] + m.data[1][0] * x + m.data[1][1] * y + m.data[1][2] * z},
                []f32{m.data[2][0], m.data[2][1], m.data[2][2], m.data[2][3] + m.data[2][0] * x + m.data[2][1] * y + m.data[2][2] * z},
                []f32{m.data[3][0], m.data[3][1], m.data[3][2], m.data[3][3]},
            },
        }
    }

    pub fn translate_by_vec(m: Mat4x4, v: Vec3) -> Mat4x4 {
        m.translate(v.data[0], v.data[1], v.data[2])
    }


    /// Builds a scale 4 * 4 matrix created from 3 scalars.
    /// Input matrix multiplied by this scale matrix.
    pub fn scale(m: Mat4x4, x: f32, y: f32, z: f32) -> Mat4x4 {
        Mat4x4 {
            .data = [][4]f32{
                []f32{m.data[0][0] * x, m.data[0][1] * y, m.data[0][2] * z, m.data[0][3]},
                []f32{m.data[1][0] * x, m.data[1][1] * y, m.data[1][2] * z, m.data[1][3]},
                []f32{m.data[2][0] * x, m.data[2][1] * y, m.data[2][2] * z, m.data[2][3]},
                []f32{m.data[3][0] * x, m.data[3][1] * y, m.data[3][2] * z, m.data[3][3]},
            },
        }
    }
}

pub const mat4x4_identity = Mat4x4 {
    .data = [][4]f32{
        []f32{1.0, 0.0, 0.0, 0.0},
        []f32{0.0, 1.0, 0.0, 0.0},
        []f32{0.0, 0.0, 1.0, 0.0},
        []f32{0.0, 0.0, 0.0, 1.0},
    },
};

/// Creates a matrix for an orthographic parallel viewing volume.
pub fn mat4x4_ortho(left: f32, right: f32, bottom: f32, top: f32) -> Mat4x4 {
    var m = mat4x4_identity;
    m.data[0][0] = 2.0 / (right - left);
    m.data[1][1] = 2.0 / (top - bottom);
    m.data[2][2] = -1.0;
    m.data[0][3] = -(right + left) / (right - left);
    m.data[1][3] = -(top + bottom) / (top - bottom);
    m
}

pub struct Vec3 {
    data: [3]f32,

    pub fn normalize(v: Vec3) -> Vec3 {
        v.scale(1.0 / sqrtf(v.dot(v)))
    }

    pub fn scale(v: Vec3, scalar: f32) -> Vec3 {
        Vec3 {
            .data = []f32 {
                v.data[0] * scalar,
                v.data[1] * scalar,
                v.data[2] * scalar,
            },
        }
    }

    pub fn dot(v: Vec3, other: Vec3) -> f32 {
        v.data[0] * other.data[0] +
        v.data[1] * other.data[1] +
        v.data[2] * other.data[2]
    }
}


pub fn vec3(x: f32, y: f32, z: f32) -> Vec3 {
    Vec3 {
        .data = []f32 { x, y, z, },
    }
}

pub struct Vec4 {
    data: [4]f32,
}

pub fn vec4(a: f32, b: f32, c: f32, d: f32) -> Vec4 {
    Vec4 {
        .data = []f32 { a, b, c, d, },
    }
}

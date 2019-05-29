const c = @import("c_with_glfw.zig");

pub const StaticGeometry = struct {
    rect_2d_vertex_buffer: c.GLuint,
    rect_2d_tex_coord_buffer: c.GLuint,

    triangle_2d_vertex_buffer: c.GLuint,
    triangle_2d_tex_coord_buffer: c.GLuint,

    pub fn create() StaticGeometry {
        var sg: StaticGeometry = undefined;

        const rect_2d_vertexes = [][3]c.GLfloat{
            []c.GLfloat{ 0.0, 0.0, 0.0 },
            []c.GLfloat{ 0.0, 1.0, 0.0 },
            []c.GLfloat{ 1.0, 0.0, 0.0 },
            []c.GLfloat{ 1.0, 1.0, 0.0 },
        };
        c.glGenBuffers(1, &sg.rect_2d_vertex_buffer);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, sg.rect_2d_vertex_buffer);
        c.glBufferData(c.GL_ARRAY_BUFFER, 4 * 3 * @sizeOf(c.GLfloat), @ptrCast(*const c_void, &rect_2d_vertexes[0][0]), c.GL_STATIC_DRAW);

        const rect_2d_tex_coords = [][2]c.GLfloat{
            []c.GLfloat{ 0, 0 },
            []c.GLfloat{ 0, 1 },
            []c.GLfloat{ 1, 0 },
            []c.GLfloat{ 1, 1 },
        };
        c.glGenBuffers(1, &sg.rect_2d_tex_coord_buffer);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, sg.rect_2d_tex_coord_buffer);
        c.glBufferData(c.GL_ARRAY_BUFFER, 4 * 2 * @sizeOf(c.GLfloat), @ptrCast(*const c_void, &rect_2d_tex_coords[0][0]), c.GL_STATIC_DRAW);

        const triangle_2d_vertexes = [][3]c.GLfloat{
            []c.GLfloat{ 0.0, 0.0, 0.0 },
            []c.GLfloat{ 0.0, 1.0, 0.0 },
            []c.GLfloat{ 1.0, 0.0, 0.0 },
        };
        c.glGenBuffers(1, &sg.triangle_2d_vertex_buffer);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, sg.triangle_2d_vertex_buffer);
        c.glBufferData(c.GL_ARRAY_BUFFER, 3 * 3 * @sizeOf(c.GLfloat), @ptrCast(*const c_void, &triangle_2d_vertexes[0][0]), c.GL_STATIC_DRAW);

        const triangle_2d_tex_coords = [][2]c.GLfloat{
            []c.GLfloat{ 0, 0 },
            []c.GLfloat{ 0, 1 },
            []c.GLfloat{ 1, 0 },
        };
        c.glGenBuffers(1, &sg.triangle_2d_tex_coord_buffer);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, sg.triangle_2d_tex_coord_buffer);
        c.glBufferData(c.GL_ARRAY_BUFFER, 3 * 2 * @sizeOf(c.GLfloat), @ptrCast(*const c_void, &triangle_2d_tex_coords[0][0]), c.GL_STATIC_DRAW);

        return sg;
    }

    pub fn destroy(sg: *StaticGeometry) void {
        c.glDeleteBuffers(1, &sg.rect_2d_tex_coord_buffer);
        c.glDeleteBuffers(1, &sg.rect_2d_vertex_buffer);

        c.glDeleteBuffers(1, &sg.triangle_2d_vertex_buffer);
        c.glDeleteBuffers(1, &sg.triangle_2d_tex_coord_buffer);
    }
};

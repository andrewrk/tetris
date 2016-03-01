use @import("libc.zig");

pub struct StaticGeometry {
    rect_2d_vertex_buffer: GLuint,
    rect_2d_tex_coord_buffer: GLuint,

    triangle_2d_vertex_buffer: GLuint,
    triangle_2d_tex_coord_buffer: GLuint,

    pub fn destroy(sg: &StaticGeometry) {
        glDeleteBuffers(1, &sg.rect_2d_tex_coord_buffer);
        glDeleteBuffers(1, &sg.rect_2d_vertex_buffer);

        glDeleteBuffers(1, &sg.triangle_2d_vertex_buffer);
        glDeleteBuffers(1, &sg.triangle_2d_tex_coord_buffer);
    }
}

pub fn create_static_geometry() -> StaticGeometry {
    var sg: StaticGeometry = undefined;

    const rect_2d_vertexes = [][3]GLfloat {
        []GLfloat{0.0, 0.0, 0.0},
        []GLfloat{0.0, 1.0, 0.0},
        []GLfloat{1.0, 0.0, 0.0},
        []GLfloat{1.0, 1.0, 0.0},
    };
    glGenBuffers(1, &sg.rect_2d_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, sg.rect_2d_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, 4 * 3 * @sizeof(GLfloat), (&c_void)(&rect_2d_vertexes[0][0]), GL_STATIC_DRAW);


    const rect_2d_tex_coords = [][2]GLfloat{
        []GLfloat{0, 0},
        []GLfloat{0, 1},
        []GLfloat{1, 0},
        []GLfloat{1, 1},
    };
    glGenBuffers(1, &sg.rect_2d_tex_coord_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, sg.rect_2d_tex_coord_buffer);
    glBufferData(GL_ARRAY_BUFFER, 4 * 2 * @sizeof(GLfloat), (&c_void)(&rect_2d_tex_coords[0][0]), GL_STATIC_DRAW);



    const triangle_2d_vertexes = [][3]GLfloat {
        []GLfloat{0.0, 0.0, 0.0},
        []GLfloat{0.0, 1.0, 0.0},
        []GLfloat{1.0, 0.0, 0.0},
    };
    glGenBuffers(1, &sg.triangle_2d_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, sg.triangle_2d_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, 3 * 3 * @sizeof(GLfloat), (&c_void)(&triangle_2d_vertexes[0][0]), GL_STATIC_DRAW);


    const triangle_2d_tex_coords = [][2]GLfloat{
        []GLfloat{0, 0},
        []GLfloat{0, 1},
        []GLfloat{1, 0},
    };
    glGenBuffers(1, &sg.triangle_2d_tex_coord_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, sg.triangle_2d_tex_coord_buffer);
    glBufferData(GL_ARRAY_BUFFER, 3 * 2 * @sizeof(GLfloat), (&c_void)(&triangle_2d_tex_coords[0][0]), GL_STATIC_DRAW);


    return sg;
}

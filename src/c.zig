pub usingnamespace @cImport({
    @cInclude("stdio.h");
    @cInclude("math.h");
    @cInclude("time.h");
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
    @cDefine("STBI_ONLY_PNG", "");
    @cDefine("STBI_NO_STDIO", "");
    @cInclude("stb_image.h");
});

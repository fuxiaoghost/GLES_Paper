
// 输入 顶点位置和法向量
attribute vec4 vVertex;
attribute vec2 vTexCoord;

// 设置每个批次
uniform mat4 mvpMatrix;             // 投影变换矩阵
uniform mat4 mvMatrix;              // 模型矩阵

varying vec2 vVaryingTexCoord;

void main(void){
    vVaryingTexCoord = vTexCoord;
    
    vec4 position = mvpMatrix * vVertex;
    // 变换
    gl_Position = vec4(position.x,position.y,-0.0,position.w);
}
//
//  PaperFlatLight.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

// 输入 顶点位置和法向量
attribute vec4 vVertex;
attribute vec3 vNormal;

// 设置每个批次
uniform mat4 mvpMatrix;             // 投影变换矩阵
uniform mat3 normalMatrix;          // 法向量矩阵

// 传递给片段着色器
varying vec4 vVaryingVertex;
varying vec3 vVaryingNormal;

void main(void){
    
    vVaryingVertex = vVertex;
    vVaryingNormal = normalMatrix * vNormal;
    
    // 变换
    gl_Position = mvpMatrix * vVertex;
}

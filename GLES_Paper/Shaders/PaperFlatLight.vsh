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
attribute vec2 vTexCoord;

// 设置每个批次
uniform mat4 mvpMatrix;             // 投影变换矩阵
uniform mat3 normalMatrix;          // 法向量矩阵
uniform mat4 mvMatrix;              // 模型矩阵

// 传递给片段着色器
varying float v_NDotL;
varying vec4 vVaryingVertex;
varying float diff;
varying vec2 vVaryingTexCoord;

void main(void){
    vVaryingTexCoord = vTexCoord;
    
    diff = dot(normalMatrix * vNormal,vec3(0.0,0.0,1.0));
    v_NDotL = max(0.0, diff);
    
    vVaryingVertex = vVertex;
    // 变换
    gl_Position = mvpMatrix * vVertex;
}

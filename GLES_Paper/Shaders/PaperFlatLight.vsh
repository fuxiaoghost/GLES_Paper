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
uniform vec3 lightPosition;         // 光线位置
uniform vec4 lightColor;            // 光线颜色

// 传递给片段着色器
varying vec4 vVaryingVertex;
varying float diff;
varying vec2 vVaryingTexCoord;
varying vec4 vVaryingColor;
varying float zDistance;

void main(void){
    vVaryingTexCoord = vTexCoord;
    
    vec4 vPosition4 = mvMatrix * vVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    vec3 vVaryingLight = normalize(lightPosition - vPosition3);
    diff = dot(normalize(normalMatrix * vNormal),vVaryingLight);
    float diff2 = max(0.0,diff);
    
    vVaryingColor = lightColor * diff2;
    vec4 zVertex = mvMatrix * vec4(0,0,0,1);
    zDistance = abs(zVertex.z);
    
    vVaryingVertex = vVertex;
    // 变换
    gl_Position = mvpMatrix * vVertex;
}

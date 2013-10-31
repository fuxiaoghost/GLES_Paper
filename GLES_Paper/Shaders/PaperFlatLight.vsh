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
uniform vec4 diffuseColor;          // 漫射光颜色
uniform vec3 vLightPosition;        // 光源位置
uniform mat4 mvpMatrix;             // 投影变换矩阵
uniform mat4 mvMatrix;              // 模型矩阵
uniform mat3 normalMatrix;          // 法向量矩阵

// 传递给片段着色器
varying vec4 vVaryingColor;
varying vec4 vVaryingVertex;
varying float varyingDiff;

void main(void){
    // 获取表面法线的视觉坐标
    vec3 vEyeNormal = normalMatrix * vNormal;
    // 获取顶点位置的视觉坐标
    vec4 vPosition4 = mvMatrix * vVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    // 获取到光源的向量
    vec3 vLightDir = normalize(vLightPosition - vPosition3);
    // 从点乘积得到漫反射强度
    varyingDiff = dot(vEyeNormal,vLightDir);
    float diff = max(0.0,varyingDiff);
    
    // 用强度乘以漫反射颜色，将alpha设置为1.0
    vVaryingColor.xyz = diff * diffuseColor.xyz;
    vVaryingColor.a = 1.0;
    
    // 环境光
    vec4 ambientColor = vec4(0.2,0.2,0.2,1.0);
    vVaryingColor += ambientColor;
    
    // 传递定点
    vVaryingVertex = vVertex;
    
    // 变换
    gl_Position = mvpMatrix * vVertex;
}

//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

uniform int backHide;
uniform float radius;
uniform vec4 diffuseColor;          // 漫射光颜色
uniform vec4 ambientColor;
uniform vec3 vLightPosition;        // 光源位置
uniform mat4 mvMatrix;              // 模型矩阵

varying vec4 vVaryingVertex;
varying vec3 vVaryingNormal;

void main(void){
    vec4 vPosition4 = mvMatrix * vVaryingVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    vec3 vVaryingLight = normalize(vLightPosition - vPosition3);
    
    float diff = dot(normalize(vVaryingNormal),normalize(vVaryingLight));
    if (backHide == 1) {
        if (diff < -0.2) {
            discard;
        }
    }
    
    diff = max(0.0,diff);
    
    float y = vVaryingVertex.y;
    float z = vVaryingVertex.z;
    if (y > 1.0 - radius && z > 1.0 - radius) {
        if (distance(vVaryingVertex.yz,vec2(1.0 - radius,1.0 - radius)) > radius) {
            discard;
        }
    }else if(y < -1.0 + radius && z > 1.0 - radius){
        if (distance(vVaryingVertex.yz,vec2(radius - 1.0,1.0 - radius)) > radius) {
            discard;
        }
    }
    
    
    // 漫射光
    gl_FragColor = diff * diffuseColor;
    
    // 环境光
    gl_FragColor += ambientColor;
}

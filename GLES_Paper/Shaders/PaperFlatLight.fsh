//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

uniform int backHide;
uniform float radiusY;
uniform float radiusZ;
uniform sampler2D colorMap;
uniform int leftHalf;
uniform float z0;                   //
uniform float z1;                   //

varying vec4 vVaryingVertex;
varying float diff;
varying vec2 vVaryingTexCoord;
varying vec4 vVaryingColor;
varying float zDistance;

void main(void){

    // 背面不渲染
    if (backHide == 1) {
        if (diff < -0.2) {
            discard;
        }
    }
    
    // 圆角
//    float y = vVaryingVertex.y;
//    float z = vVaryingVertex.z;
//    if (y > 1.0 - radiusY && z > 1.0 - radiusZ) {
//        float ty = y - (1.0-radiusY);
//        float tz = z - (1.0-radiusZ);
//        if ((ty * ty) / (radiusY * radiusY) + (tz * tz)/(radiusZ * radiusZ) > 1.0) {
//            discard;
//        }
//    }else if(y < -1.0 + radiusY && z > 1.0 - radiusZ){
//        float ty = abs(y) - (1.0 - radiusY);
//        float tz = abs(z) - (1.0 - radiusZ);
//        if ((ty * ty) / (radiusY * radiusY) + (tz * tz)/(radiusZ * radiusZ) > 1.0) {
//            discard;
//        }
//    }
    lowp vec4 textureColor = texture2D(colorMap,vVaryingTexCoord);
    
    if (leftHalf == 1) {
        // 左侧页加渐变灰
        lowp vec4 leftCoverColor = vec4(1.0,1.0,1.0,1.0);
        leftCoverColor.rgb = mix(vec3(0.0,0.0,0.0),vec3(0.1,0.1,0.1),vVaryingTexCoord.s);
        gl_FragColor = vVaryingColor - leftCoverColor * (min(1.0,mix(0.0,1.0,zDistance/z0)));
    }else{
        gl_FragColor = vVaryingColor;
    }
    
    // 环境光
    vec3 ambientLight = vec3(0.3,0.3,0.3);
    ambientLight *= min(1.0,mix(0.0,1.0,zDistance/z0));
    gl_FragColor.rgb += ambientLight;
    
    if (zDistance <= 0.0) {
        gl_FragColor.rgb = vec3(1.0,1.0,1.0);
    }
    
    // 随Z轴变化
    gl_FragColor.rgb *= mix(1.0,0.6,zDistance/z1);
    
    gl_FragColor *= textureColor;
}

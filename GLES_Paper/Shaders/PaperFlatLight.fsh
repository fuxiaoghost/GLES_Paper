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
uniform sampler2D colorMap;
uniform int leftHalf;

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
    lowp vec4 textureColor = texture2D(colorMap,vVaryingTexCoord);
    
    if (leftHalf == 1) {
        // 左侧页加渐变灰
        lowp vec4 leftCoverColor = vec4(1.0,1.0,1.0,1.0);
        leftCoverColor.rgb = mix(vec3(0.0,0.0,0.0),vec3(0.1,0.1,0.1),vVaryingTexCoord.s);
        gl_FragColor = vVaryingColor - leftCoverColor * mix(1.0,0.6,zDistance/5.0);
    }else{
        gl_FragColor = vVaryingColor;
    }
    
    // 环境光
    gl_FragColor.rgb += vec3(0.3,0.3,0.3);
    
    // 随Z轴变化
    gl_FragColor.rgb *= mix(1.0,0.6,zDistance/5.0);
    
    gl_FragColor *= textureColor;
}

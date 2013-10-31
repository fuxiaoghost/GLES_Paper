//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

uniform bool backHidden;

varying vec4 vVaryingColor;
varying vec4 vVaryingVertex;
varying float varyingDiff;

void main(void){
    if (backHidden) {
        if (varyingDiff < -0.1) {
            discard;
        }
    }
    
    
    float y = vVaryingVertex.y;
    float z = vVaryingVertex.z;
    float radius = 0.1;
    if (y > 1.0 - radius && z > 1.0 - radius) {
        if (distance(vVaryingVertex.yz,vec2(1.0 - radius,1.0 - radius)) > radius) {
            discard;
        }
    }else if(y < -1.0 + radius && z > 1.0 - radius){
        if (distance(vVaryingVertex.yz,vec2(radius - 1.0,1.0 - radius)) > radius) {
            discard;
        }
    }
    gl_FragColor = vVaryingColor;
}

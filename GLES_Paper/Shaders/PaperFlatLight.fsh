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

uniform lowp float u_FlippingPageEdge;

uniform lowp float u_RightHalfFlipping;

uniform vec3 u_HighlightColor;
uniform float u_HighlightAlpha;
uniform sampler2D colorMap;


varying vec4 vVaryingVertex;
varying float diff;
varying mediump float v_NDotL;
varying vec2 vVaryingTexCoord;

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
    
    lowp vec4 computedColor = texture2D(colorMap,vVaryingTexCoord);
    
    lowp float leftHalf = step(vVaryingTexCoord.x, 0.5);
    lowp float rightHalf = step(0.5, vVaryingTexCoord.x);
    
    lowp float occludedPageShadow = 1.0
    - rightHalf * step(0.0, u_FlippingPageEdge) * mix(0.0,0.45,u_FlippingPageEdge)
    - leftHalf * step(u_FlippingPageEdge,0.0) * mix(0.0, 0.45, -u_FlippingPageEdge);
    
    lowp float flippingPageShadow = mix(mix(0.75,1.0,v_NDotL), 1.0, 2.0 * abs(vVaryingTexCoord.x - 0.5));
    lowp float flippingHalf = mix(leftHalf, rightHalf, u_RightHalfFlipping);
    
    computedColor.xyz *= mix(occludedPageShadow, flippingPageShadow, flippingHalf);
    computedColor.rgb = mix(computedColor.rgb, u_HighlightColor，u_HighlightAlpha);
    
    gl_FragColor = computedColor;
}

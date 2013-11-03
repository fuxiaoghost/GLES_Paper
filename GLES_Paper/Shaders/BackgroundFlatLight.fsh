//
//  BackgroundFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

precision mediump float;

uniform mat4 mvMatrix;
uniform vec3 vLightPosition;
uniform vec4 ambientColor;
uniform vec4 diffuseColor;
uniform sampler2D colorMap;

varying vec4 vVaryingVertex;
varying vec3 vVaryingNormal;
varying vec2 vVaryingTexCoord;

void main(void){

    vec4 vPosition4 = mvMatrix * vVaryingVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    
    vec3 vVaryingLight = normalize(vLightPosition - vPosition3);
    
    
    float diff = max(0.0,dot(normalize(vVaryingNormal),normalize(vVaryingLight)));
    
    // 漫射光
    gl_FragColor = diff * diffuseColor;
    
    // 环境光
    gl_FragColor += ambientColor;
    
    //lowp vec4 textureColor = texture2D(colorMap,vVaryingTexCoord);
    //gl_FragColor *= textureColor;
}

//
//  BackgroundFlatLight.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

attribute vec4 vVertex;
attribute vec3 vNormal;
attribute vec2 vTexture0;

uniform mat4 mvpMatrix;
uniform mat4 mvMatrix;
uniform mat3 normalMatrix;
uniform vec3 vLightPosition;

varying vec3 vVaryingNormal;
varying vec3 vVaryingLight;
varying vec2 vTextCoords;

void main(void){
    vVaryingNormal = normalMatrix * vNormal;
    
    vec4 vPosition4 = mvMatrix * vVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    
    vVaryingLight = normalize(vLightPosition - vPosition3);
    
    vTextCoords = vTexture0.st;
    
    gl_Position = mvpMatrix * vVertex;
}
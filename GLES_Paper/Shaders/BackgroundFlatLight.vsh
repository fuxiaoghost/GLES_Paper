//
//  BackgroundFlatLight.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

attribute vec4 vVertex;
attribute vec3 vNormal;
attribute vec2 vTexCoord;

uniform mat4 mvpMatrix;
uniform mat3 normalMatrix;

varying vec4 vVaryingVertex;
varying vec3 vVaryingNormal;
varying vec2 vVaryingTexCoord;

void main(void){
    vVaryingVertex = vVertex;
    vVaryingNormal = normalMatrix * vNormal;
    vVaryingTexCoord = vTexCoord;
    
    gl_Position = mvpMatrix * vVertex;
}
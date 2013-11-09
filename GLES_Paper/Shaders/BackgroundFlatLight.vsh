//
//  BackgroundFlatLight.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

attribute highp   vec4 vVertex;
attribute mediump vec3 vNormal;

varying lowp  vec4 colorVarying;
varying highp vec4 shadowCoord;

uniform highp   mat4 mvpMatrix;
uniform highp   mat4 mvMatrix;
uniform mediump mat3 normalMatrix;
uniform highp   mat4 mvsMatrix;
uniform mediump vec3 lightPosition;
uniform lowp    vec3 lightColor;

void main()
{
    // get the projected vertex position
    gl_Position = mvpMatrix * vVertex;
    
    vec4 vPosition4 = mvMatrix * vVertex;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
    vec3 vVaryingLight = normalize(lightPosition - vPosition3);
    
    // calculate the diffuse light contribution
    mediump vec3 eyeNormal = normalize(normalMatrix * vNormal);
    mediump float nDotVP = max(0.0, dot(eyeNormal, vVaryingLight));
    colorVarying = vec4(lightColor * nDotVP, 1.0);
    colorVarying = vec4(0.4,0.4,0.4,1.0);
    // calculate the coordinates to use in the shadow texture
    shadowCoord = mvsMatrix * vVertex;
}

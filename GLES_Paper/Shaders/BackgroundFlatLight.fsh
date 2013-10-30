//
//  BackgroundFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

precision mediump float;

varying vec3 vVaryingNormal;
varying vec3 vVaryingLight;
varying vec2 vTextCoords;

uniform vec4 ambientColor;
uniform vec4 diffuseColor;
uniform vec4 specularColor;
uniform sampler2D colorMap;

void main(void){
    float diff = max(0.0,dot(normalize(vVaryingNormal),normalize(vVaryingLight)));
    
    // 漫射光
    gl_FragColor = diff * diffuseColor;
    
    // 环境光
    gl_FragColor += ambientColor;
    
    // 纹理
    gl_FragColor *= texture2D(colorMap,vTextCoords);
    
    // 镜面光
    vec3 vReflection = normalize(reflect(-normalize(vVaryingLight),normalize(vVaryingNormal)));
    float spec = max(0.0,dot(normalize(vVaryingNormal),vReflection));
    
    if(diff != 0.0){
        float fSpec = pow(spec,128.0);
        gl_FragColor.rgb += vec3(fSpec,fSpec,fSpec);
    }
}

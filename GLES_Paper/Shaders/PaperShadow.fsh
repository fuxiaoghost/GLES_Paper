//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

varying vec2 vVaryingTexCoord;
uniform sampler2D colorMap;

void main(void){
    lowp vec4 textureColor = texture2D(colorMap,vVaryingTexCoord);
    
    gl_FragColor = textureColor;
}

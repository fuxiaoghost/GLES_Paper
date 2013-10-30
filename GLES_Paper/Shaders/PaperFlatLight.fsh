//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

varying vec4 vVaryingColor;

void main(void){
    gl_FragColor = vVaryingColor;
}

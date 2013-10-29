//
//  PaperFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-29.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//
precision mediump float;

varying lowp vec4 colorVarying;

void main(){
    gl_FragColor = colorVarying;
}

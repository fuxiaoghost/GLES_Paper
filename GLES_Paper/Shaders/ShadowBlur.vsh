//
//  ShadowBlur.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-11-7.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

attribute vec4 vVertex;
attribute vec2 vTexCoord;

varying vec2 vVaryingTexCoord;

void main(){
    gl_Position = vVertex;
    vVaryingTexCoord = vTexCoord;
}
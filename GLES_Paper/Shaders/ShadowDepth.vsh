//
//  ShadowColor.vsh
//  GLES_Paper
//
//  Created by Dawn on 13-11-7.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//


attribute vec4 vVertex;         
uniform mat4 mvpMatrix;

void main(){
    gl_Position = mvpMatrix * vVertex;
}

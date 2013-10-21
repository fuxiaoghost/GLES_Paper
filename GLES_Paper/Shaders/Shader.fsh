//
//  Shader.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}

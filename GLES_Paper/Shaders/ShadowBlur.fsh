//
//  ShadowBlur.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-11-7.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

varying mediump vec2 vVaryingTexCoord;

uniform sampler2D colorMap;
uniform mediump vec2 pixelStep;
uniform mediump float offsets[3];
uniform lowp float weights[3];

// 9 tap gaussian filter implemented using linear filtering with 5 samples
// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

void main()
{
    lowp vec4 color = texture2D(colorMap, vVaryingTexCoord) * weights[0];
    for (int i = 1; i < 3; i++)
    {
        color += texture2D(colorMap, vVaryingTexCoord - offsets[i] * pixelStep) * weights[i];
        color += texture2D(colorMap, vVaryingTexCoord + offsets[i] * pixelStep) * weights[i];
    }
    gl_FragColor = color;
}
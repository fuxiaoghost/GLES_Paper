//
//  BackgroundFlatLight.fsh
//  GLES_Paper
//
//  Created by Dawn on 13-10-30.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

varying lowp  vec4 colorVarying;
varying highp vec4 shadowCoord;

uniform sampler2D shadowMap;

const highp float kMinVariance = 0.00002;
const lowp  float kShadowAmount = 0.4;

lowp float chebyshevUpperBound(highp vec3 coords)
{
	highp vec2 moments = texture2D(shadowMap, coords.xy).rg;
    
	// If the fragment is in front of the occluder, then it is fully lit.
    if (coords.z <= moments.r)
        return 1.0;
    
	// The fragment is either in shadow or penumbra.
    // Calculate the variance and clamp to a min value
    // to avoid self shadowing artifacts.
	highp float variance = moments.g - (moments.r * moments.r);
	variance = max(variance, kMinVariance);
    
    // Calculate the probabilistic upper bound.
	highp float d = coords.z - moments.r;
    lowp float p_max = variance / (variance + d*d);
    
	return p_max;
}

void main()
{
    highp vec3 postWCoord = shadowCoord.xyz / shadowCoord.w;
    lowp float pShadow = chebyshevUpperBound(postWCoord);
    
    gl_FragColor = colorVarying * (1.0 - kShadowAmount + kShadowAmount * pShadow);
}

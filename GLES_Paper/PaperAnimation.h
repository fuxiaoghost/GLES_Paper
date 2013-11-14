//
//  PaperAnimation.h
//  GLES_Paper
//
//  Created by Dawn on 13-11-13.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PaperAnimation : NSObject{
@private
    float animationValueFrom;
    float animationValueTo;
    float animationValueBy;
    float *animationValue;
    float animationTimeOffset;
    float animationTimeEnd;
    float animationTimeDelay;
}
- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay;

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay;

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay completion:(void (^)(BOOL finished))completion;

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay completion:(void (^)(BOOL finished))completion;

- (void) stopAnimation;
@end

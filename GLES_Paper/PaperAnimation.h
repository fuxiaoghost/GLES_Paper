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
}
- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo;

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo;

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL finished))completion;

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL finished))completion;

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL))completion valueChanged:(void(^)(float value)) valueChanged;

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL))completion valueChanged:(void(^)(float value)) valueChanged;

- (void) stopAnimation;
@end

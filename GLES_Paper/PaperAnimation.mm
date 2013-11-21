//
//  PaperAnimation.m
//  GLES_Paper
//
//  Created by Dawn on 13-11-13.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//


#import "PaperAnimation.h"
#import <QuartzCore/QuartzCore.h>

@interface PaperAnimation()
@property (nonatomic,copy) void (^completion)(BOOL finished);
@property (nonatomic,copy) void (^valueChanged)(float value);
@end

@implementation PaperAnimation

- (void) dealloc{
    self.completion = nil;
    self.valueChanged = nil;
    [super dealloc];
}


- (void) stopAnimation{
    self.valueChanged = nil;
}

#pragma mark -
#pragma mark BaseAnimation
- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo{
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
    if (self.valueChanged) {
        self.valueChanged = nil;
    }
    // 加速
    animationTimeOffset = 0.0f;
    animationTimeEnd = time;
    animationValue = valueFrom;
    animationValueFrom = *valueFrom;
    animationValueTo = valueTo;
    animationValueBy = *valueFrom;
    bezierPower = 2;
    needStep = YES;
}

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo{
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
    if (self.valueChanged) {
        self.valueChanged = nil;
    }
    // 减速
    animationTimeOffset = 0.0f;
    animationTimeEnd = time;
    animationValue = valueFrom;
    animationValueFrom = *valueFrom;
    animationValueTo = valueTo;
    animationValueBy = valueTo;
    bezierPower = 2;
    needStep = YES;
}

- (void) animateEasyInOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo{
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
    if (self.valueChanged) {
        self.valueChanged = nil;
    }
    // 减速
    animationTimeOffset = 0.0f;
    animationTimeEnd = time;
    animationValue = valueFrom;
    animationValueFrom = *valueFrom;
    animationValueTo = valueTo;
    animationValueBy = valueTo;
    bezierPower = 3;
    needStep = YES;
}

#pragma mark -
#pragma mark Animation With Completion
- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL finished))completion {
    
    [self animateEasyOutWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    
    self.completion = completion;
}

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL finished))completion {
   
    [self animateEasyInWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    
    self.completion = completion;
}

- (void) animateEasyInOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo
                           completion:(void (^)(BOOL finished))completion{
    [self animateEasyInOutWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    self.completion = completion;
    
}

#pragma mark -
#pragma mark Animation With Completion And ValueChanged

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL))completion valueChanged:(void(^)(float value))valueChanged{
    [self animateEasyOutWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    
    self.completion = completion;
    self.valueChanged = valueChanged;
}

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL))completion valueChanged:(void(^)(float Z))valueChanged{
    [self animateEasyInWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    
    self.completion = completion;
    self.valueChanged = valueChanged;
}

- (void) animateEasyInOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo completion:(void (^)(BOOL))completion valueChanged:(void(^)(float Z))valueChanged{
    [self animateEasyInOutWithDuration:time valueFrom:valueFrom valueTo:valueTo];
    self.completion = completion;
    self.valueChanged = valueChanged;
}

- (void) animationTimerStep:(float)duration{
    if (!needStep) {
        return;
    }
    animationTimeOffset += duration;
    if (animationTimeOffset >= animationTimeEnd) {
        *animationValue = animationValueTo;
        if (self.completion) {
            self.completion(YES);
            self.completion = nil;
        }
        needStep = NO;
    }else{
        float t = (animationTimeOffset)/animationTimeEnd;
        if (bezierPower == 2) {
            *animationValue = [self bezierValueFrom:animationValueFrom to:animationValueTo by:animationValueTo t:t];
        }else if(bezierPower == 3){
            *animationValue = [self bezierValueFrom:animationValueFrom to:animationValueTo by0:animationValueFrom by1:animationValueTo t:t];
        }
        
        if (self.valueChanged) {
            self.valueChanged(*animationValue);
        }
    }
}
- (float) bezierValueFrom:(float)valueFrom to:(float)valueTo by:(float)valueBy t:(float)t{
    return (1.0f - t) * (1.0f - t) * valueFrom
            + 2 * t * (1.0f - t) * valueBy
            + t * t * valueTo;
}

- (float) bezierValueFrom:(float)valueFrom to:(float)valueTo by0:(float)valueBy0 by1:(float)valueBy1 t:(float)t{
    return (1.0f - t) * (1.0f - t) * (1.0f - t) * valueFrom
            + 3 * t * (1.0 - t) * (1.0 - t) * valueBy0
            + 3 * t * t * (1.0 - t) * valueBy1
            + t * t * t * valueTo;
}
@end

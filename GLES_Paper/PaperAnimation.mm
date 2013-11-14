//
//  PaperAnimation.m
//  GLES_Paper
//
//  Created by Dawn on 13-11-13.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//


#define STEPSPERSECOND 60

#import "PaperAnimation.h"
@interface PaperAnimation()
@property (nonatomic,retain) NSTimer *animationTimer;
@property (nonatomic,copy) void (^completion)(BOOL finished);
@end

@implementation PaperAnimation
@synthesize animationTimer;

- (void) dealloc{
    self.completion = nil;
    [super dealloc];
}


- (void) stopAnimation{
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    NSLog(@"Animation stop");
}

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay{
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
    // 加速
    animationTimeOffset = 0.0f;
    animationTimeEnd = time;
    animationValue = valueFrom;
    animationValueFrom = *valueFrom;
    animationValueTo = valueTo;
    animationValueBy = *valueFrom;
    animationTimeDelay = delay>0?delay:0;
    
    if (!self.animationTimer) {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/STEPSPERSECOND
                                                               target:self
                                                             selector:@selector(animationTimerStep)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay{
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
    // 减速
    animationTimeOffset = 0.0f;
    animationTimeEnd = time;
    animationValue = valueFrom;
    animationValueFrom = *valueFrom;
    animationValueTo = valueTo;
    animationValueBy = valueTo;
    animationTimeDelay = delay>0?delay:0;

   
    if (!self.animationTimer) {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/STEPSPERSECOND
                                                               target:self
                                                             selector:@selector(animationTimerStep)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (void) animateEasyOutWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay completion:(void (^)(BOOL finished))completion {
    
    [self animateEasyOutWithDuration:time valueFrom:valueFrom valueTo:valueTo delay:delay];
    
    self.completion = completion;
}

- (void) animateEasyInWithDuration:(NSTimeInterval)time valueFrom:(float *)valueFrom valueTo:(float)valueTo delay:(float)delay completion:(void (^)(BOOL finished))completion {
   
    [self animateEasyInWithDuration:time valueFrom:valueFrom valueTo:valueTo delay:delay];
    
     self.completion = completion;
}

- (void) animationTimerStep{
    animationTimeOffset += (1.0/STEPSPERSECOND);
    if (animationTimeOffset < animationTimeDelay) {
        return;
    }
    if (animationTimeOffset >= animationTimeEnd + animationTimeDelay) {
        *animationValue = animationValueTo;
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        if (self.completion) {
            self.completion(YES);
            self.completion = nil;
        }
        NSLog(@"Animation end of time out");
    }else{
        float t = (animationTimeOffset - animationTimeDelay)/animationTimeEnd;
        *animationValue =[self bezierValueFrom:animationValueFrom to:animationValueTo by:animationValueBy t:t];
        
        //NSLog(@"Animation to:%f",*animationValue);
    }
}
- (float) bezierValueFrom:(float)valueFrom to:(float)valueTo by:(float)valueBy t:(float)t{
    return (1.0f - t) * (1.0f - t) * valueFrom + 2 * t * (1.0f - t) * valueBy + t * t * valueTo;
}
@end

//
//  ViewController.h
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

typedef enum {
    PaperNormal,
    PaperFold,
    PaperUnfold
}PaperStatus;

typedef struct {
    GLint lightColor;
    GLint lightPosition;
    GLint mvpMatrix;
    GLint mvMatrix;
    GLint normalMatrix;
    GLint shaderId;
}PaperFlatLightShader;

typedef struct {
    GLint mvpMatrix;
    GLint mvMatrix;
    GLint normalMatrix;
    GLint lightPosition;
    GLint ambientColor;
    GLint diffuseColor;
    GLint specularColor;
    GLint colorMap;
    GLint shaderId;
}BackgroundFlatLightShader;

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "GLTools.h"
#import "GLShaderManager.h"
#import "GLBatch.h"
#import "GLFrame.h"
#import "GLFrustum.h"
#import "GLMatrixStack.h"
#import "GLGeometryTransform.h"
#import "StopWatch.h"

@interface ViewController : GLKViewController{
@private
    float angel;
    GLShaderManager     shaderManager;          // 着色器
    GLFrame             viewFrame;              // 相机
    GLFrustum           viewFrustum;            // 透视
    
    /* 绘图批次 */
    GLBatch             *paperBatchs;           // paper批次序列
    GLBatch             backgroundBatch;        // 背景
    
    /* 绘图纹理 */
    GLuint               backgroundTexture;      // 背景纹理
    
    // 着色器
    PaperFlatLightShader paperFlatLightShader;  // 书页着色器
    BackgroundFlatLightShader backgroundFlatLightShader;    // 背景着色器
    
    
    GLMatrixStack       modelViewMatix;         // 模型矩阵
    GLMatrixStack       projectionMatrix;       // 投影矩阵
    GLGeometryTransform transformPipeline;      // 变换管线
    UIPanGestureRecognizer *panGesture;         // 手指滑动手势
    UIPinchGestureRecognizer *pinchGesture;     // 手指捏合手势
    BOOL isMoving;                              // 单手滑动翻页，是否正在移动
    BOOL isPinching;                            // 双手捏合，是否正在移动
    CGPoint startTouch;                         // 记录单手滑动初始位置
    CGPoint endTouch;                           // 记录单手滑动结束位置
    CGPoint pinchTouch0;                        // 记录捏合手势初始位置0
    CGPoint pinchTouch1;                        // 记录捏合手势初始位置1
    NSInteger startPageIndex;                   // 滑动开始前当前页
    float scope;                                // 手指捏合、展开的尺度
    float moveSensitivity;                      // 翻一页所需要的滑动距离
    float pinchSensitivity;                     // 捏合一页所需要的滑动距离
    float pinchSensitivity_;                    // 展开一页所需要的滑动距离
    
 
    
    //
    NSInteger nextPageIndex;                    // 下一页的预测值
    float x;
    BOOL needReset;
    CFAbsoluteTime currentTime;
    float currentX;
    float acceleration;
    
    // 停表
    CStopWatch stopWatch;
}
- (id) initWithImagePaths:(NSArray *)paths;
-(void) changeSize:(CGSize)size;
@property (nonatomic,assign) NSInteger pageIndex;
@end

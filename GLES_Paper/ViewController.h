//
//  ViewController.h
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//



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
#import "PaperAnimation.h"

// 当前书页的状态
typedef enum {
    PaperNormal,                                // 书页半开
    PaperFold,                                  // 书页合上
    PaperUnfold                                 // 书页打开
}PaperStatus;

// 书页着色器相关参数
typedef struct {
    GLint mvpMatrix;                            // 投影矩阵
    GLint mvMatrix;                             // 模型矩阵
    GLint normalMatrix;                         // 法线矩阵
    GLint backHide;                             // 是否渲染背面
    GLint colorMap;                             // 纹理ID
    GLint lightPosition;                        // 光线位置
    GLint lightColor;                           // 光线颜色
    GLint leftHalf;                             // 左边书页1，右边书页0
    GLint fovy;                                 // 视场角
    GLint z0;
    GLint z1;
    GLint radiusZ;
    GLint radiusY;
    GLint shaderId;                             // 着色器ID
}PaperFlatLightShader;

// 书页着色器
typedef struct {
    GLint mvpMatrix;                            // 投影矩阵
    GLint mvMatrix;                             // 模型矩阵
    GLint colorMap;                             // 纹理ID
    GLint shaderId;                             // 着色器ID
}PaperShadowShader;

// 背景着色器
typedef struct {
    GLint mvpMatrix;                            // 投影矩阵
    GLint mvMatrix;                             // 模型矩阵
    GLint mvsMatrix;                            // 影子的投影矩阵
    GLint normalMatrix;                         // 法线矩阵
    GLint lightPosition;                        // 光源位置
    GLint lightColor;                           // 光源颜色
    GLint shadowMap;                            // 阴影纹理ID
    GLint shaderId;                             // 着色器ID
}BackgroundFlatLightShader;

// 变换管线
typedef struct {
    GLMatrixStack       modelViewMatrix;        // 模型矩阵
    GLMatrixStack       projectionMatrix;       // 投影矩阵
    GLGeometryTransform transformPipeline;      // 变换管线
    GLFrustum           viewFrustum;            // 透视
}TransformPipeline;

// 翻页动作
typedef struct {
    float theta             = 0.0f;             // 翻页时活动页旋转的角度
    float startTheta        = 0.0f;             // 翻页前记录旋转角度
    BOOL  isMoving          = NO;               // 单手滑动翻页，是否正在移动
    float moveSensitivity   = 0.0f;             // 翻一页所需要的滑动距离
    float move              = 0.0f;             // 当前已经滑动的距离
}PaningMove;

// 捏合动作
typedef struct {
    BOOL    isPinching          = NO;           // 双手捏合，是否正在移动
    CGPoint pinchTouch0;                        // 记录捏合手势初始位置0
    CGPoint pinchTouch1;                        // 记录捏合手势初始位置1
    float   scope               = 0.0f;         // 手指捏合、展开的尺度
    float   startScope          = 0.0f;         // 手指捏合、展开的初始值
    float   pinchSensitivity    = 0.0f;         // 捏合所需要移动的距离
}PinchMove;

@interface ViewController : GLKViewController{
@private
    GLShaderManager     shaderManager;          // 着色器
    
    /* 绘图批次 */
    GLBatch             *paperBatchs;           // paper批次序列
    GLBatch             backgroundBatch;        // 背景
    
    /* 绘图纹理 */
    GLuint   paperTexture;                      // 书页纹理
    GLuint   shadowTexture;
    GLuint   *paperTextures;                    // 书页纹理数组
    
    /* 着色器 */
    PaperFlatLightShader paperFlatLightShader;              // 书页着色器
    BackgroundFlatLightShader backgroundFlatLightShader;    // 背景着色器
    PaperShadowShader paperShadowShader;                    // 书页阴影

    /* 变换管线 */
    TransformPipeline backgroundPipeline;       // 背景的变换管线
    TransformPipeline paperPipeline;            // 书页的变换管线
    
    /* 手势 */
    UIPanGestureRecognizer *panGesture;         // 手指滑动手势
    UIPinchGestureRecognizer *pinchGesture;     // 手指捏合手势
    
    /* 交互动作 */
    PaningMove paningMove;                      // 滑动翻页动作
    PinchMove pinchMove;                        // 捏合动作
    
    
    /* 插值动画 */
    PaperAnimation *paningAnimation;             // 滑动插值动画
    PaperAnimation *pinchAnimation;              //
    
    CGSize frameSize;
    NSInteger imageCount;
}
- (id) initWithImagePaths:(NSArray *)paths;
- (void) changeSize:(CGSize)size;
@property (nonatomic,assign) NSInteger pageIndex;
@end

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
    GLint radius;                               // 圆角半径
    GLint colorMap;                             // 纹理ID
    GLint lightPosition;                        // 光线位置
    GLint lightColor;                           // 光线颜色
    GLint leftHalf;                             // 左边书页1，右边书页0
    GLint fovy;                                 // 视场角
    GLint z0;
    GLint z1;
    GLint shaderId;                             // 着色器ID
}PaperFlatLightShader;

// 背景着色器
typedef struct {
    GLint mvpMatrix;                            // 投影矩阵
    GLint mvMatrix;                             // 模型矩阵
    GLint normalMatrix;                         // 法线矩阵
    GLint lightPosition;                        // 光源位置
    GLint ambientColor;                         // 环境光
    GLint diffuseColor;                         // 漫射光
    GLint specularColor;                        // 镜面光
    GLint colorMap;                             // 纹理ID
    GLint shaderId;                             // 着色器ID
}BackgroundFlatLightShader;

// 变换管线
typedef struct {
    GLMatrixStack modelViewMatrix;              // 模型矩阵
    GLMatrixStack projectionMatrix;             // 投影矩阵
    GLGeometryTransform transformPipeline;      // 变换管线
    GLFrustum     viewFrustum;                  // 透视
}TransformPipeline;

// 翻页动作
typedef struct {
    NSInteger nextPageIndex;                    // 下一页的预测值
    float x = 0;                                // 翻页时活动页移动的距离
    BOOL needReset = NO;                        // 是否需要重置
    CFAbsoluteTime currentTime = 0.0;           // 记录当前时间
    float currentX = 0;                         // 还原时记录x的当前值
    float acceleration;                         // 加速度
    float pageRemainder = 0;                    // 翻页时的进度
    BOOL isMoving = NO;                         // 单手滑动翻页，是否正在移动
    CGPoint startTouch;                         // 记录单手滑动初始位置
    CGPoint endTouch;                           // 记录单手滑动结束位置
    NSInteger startPageIndex;                   // 滑动开始前当前页
    float moveSensitivity;                      // 翻一页所需要的滑动距离
}PaningMove;

// 捏合动作
typedef struct {
    BOOL isPinching = NO;                       // 双手捏合，是否正在移动
    CGPoint pinchTouch0;                        // 记录捏合手势初始位置0
    CGPoint pinchTouch1;                        // 记录捏合手势初始位置1
    float scope = 0;                            // 手指捏合、展开的尺度
    float pinchSensitivity;                     // 捏合一页所需要的滑动距离
    float theta = 0;                            // 页夹角
    float beta = 0;                             // 旋转角
    float zMove = 0;                            // z轴移动距离
    float currentTheta = 0;
    float currentBeta = 0;
    float currentZMove = 0;
    BOOL needUnfold = NO;                       // 是否需要展开
    BOOL needNormal = NO;                       // 是否需要还原
    CFAbsoluteTime currentTime = 0.0;           // 记录当前时间
    float accelerationTheta;                    // 加速度
    float accelerationBeta;                     //
    float accelerationZ;
}PinchMove;

@interface ViewController : GLKViewController{
@private
    float angel;
    GLShaderManager     shaderManager;          // 着色器
    
    /* 绘图批次 */
    GLBatch             *paperBatchs;           // paper批次序列
    GLBatch             backgroundBatch;        // 背景
    
    /* 绘图纹理 */
    GLuint   paperTexture;                      // 书页纹理
    
    // 着色器
    PaperFlatLightShader paperFlatLightShader;  // 书页着色器
    BackgroundFlatLightShader backgroundFlatLightShader;    // 背景着色器
    
    /* 变换管线 */
    TransformPipeline backgroundPipeline;       // 背景的变换管线
    TransformPipeline paperPipeline;            // 书页的变换管线
    
    
    UIPanGestureRecognizer *panGesture;         // 手指滑动手势
    UIPinchGestureRecognizer *pinchGesture;     // 手指捏合手势
    
    /* 交互动作 */
    PaningMove paningMove;                      // 滑动翻页动作
    PinchMove pinchMove;                        // 捏合动作
    
    CStopWatch stopWatch;                       // 停表
}
- (id) initWithImagePaths:(NSArray *)paths;
-(void) changeSize:(CGSize)size;
@property (nonatomic,assign) NSInteger pageIndex;
@end

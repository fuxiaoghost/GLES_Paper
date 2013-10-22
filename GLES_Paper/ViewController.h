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

@interface ViewController : GLKViewController{
@private
    GLShaderManager     shaderManager;          // 着色器
    GLFrame             viewFrame;              // 相机
    GLFrustum           viewFrustum;            // 透视
    GLBatch             *paperBatchs;           // paper批次序列
    GLMatrixStack       modelViewMatix;         // 模型矩阵
    GLMatrixStack       projectionMatrix;       // 投影矩阵
    GLGeometryTransform transformPipeline;      // 变换管线
    float angel;
}
- (id) initWithImagePaths:(NSArray *)paths;
-(void) changeSize:(CGSize)size;
@end

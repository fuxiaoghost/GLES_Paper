//
//  ViewController.m
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    
    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;
@end

@implementation ViewController

- (void)dealloc{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [_context release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // EAGL上下文
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    // GL渲染容器层
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    // GL初始化配置
    [self setupGL];
}

- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    
    // 渲染图形
	GLfloat vVerts[] = { -0.5f, 0.0f, 0.0f,
        0.5f, 0.0f, 0.0f,
        0.0f, 0.5f, 0.0f };
    
	redBatch.Begin(GL_TRIANGLES, 3);
	redBatch.CopyVertexData3f(vVerts);
	redBatch.End();
    
    
    // 着色器
    // [self loadShaders];

    // 光照效果
    // self.effect = [[[GLKBaseEffect alloc] init] autorelease];
    // self.effect.light0.enabled = GL_TRUE;
    // self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
}

- (void)tearDownGL{
    // 清理GL的资源
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update{
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 清理画布
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    // 清除颜色缓冲区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 准备开整
    GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
	shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vRed);
	redBatch.Draw();
}

@end

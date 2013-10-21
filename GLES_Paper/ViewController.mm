//
//  ViewController.m
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

#import "ViewController.h"
#import "Define.h"

@interface ViewController () {
    
}
@property (nonatomic,retain) NSArray *imagePathArray;        // 图片地址
@property (retain, nonatomic) EAGLContext *context;

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
    self.imagePathArray = nil;
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
    }
    
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

- (id) initWithImagePaths:(NSArray *)paths{
    if (self = [super init]) {
        self.imagePathArray = paths;
    }
    return self;
}

-(void) changeSize:(CGSize)size{
	// Prevent a divide by zero
	if(size.height == 0)
		size.height = 1;
    
	// Set Viewport to window dimensions
    glViewport(0, 0, size.width, size.height);
    
    viewFrustum.SetPerspective(35.0f, float(size.width)/float(size.height), 1.0f, 1000.0f);
    
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatix, projectionMatrix);
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

// 创建所有的Paper批次
- (void) createPaperBatchArray{
    // 创建paper批次序列
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
    }
    paperBatchs = new GLBatch[self.imagePathArray.count];
    
    for (int i = 0; i < self.imagePathArray.count; i++) {
        paperBatchs[i].Begin(GL_TRIANGLES, 6);
        // 左半边三角形
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(0, 1, 0);
        
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(0, -1, 0);
        
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(-1, 1, 0);

        // 右半边三角形
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(-1, 1, 0);
        
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(0, -1, 0);
        
        paperBatchs[i].Color4f(1, 1, 1, 1);
        paperBatchs[i].Normal3f(0, 0, 1);
        paperBatchs[i].Vertex3f(-1, -1, 0);
        paperBatchs[i].End();
    }
}

- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    
    // 渲染图形
    [self createPaperBatchArray];
    
    
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
    for (int i = 0; i < self.imagePathArray.count; i++) {
        paperBatchs[i].Draw();
    }

}

#pragma mark -
#pragma mark Rotation 
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if(INTERFACE_LANDSCAPELEFT )
    
}

@end

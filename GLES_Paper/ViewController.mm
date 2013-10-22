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
@property (nonatomic,retain) UILabel *debugLabel;

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
    self.debugLabel = nil;
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
        self.debugLabel = nil;
    }
}

- (id) initWithImagePaths:(NSArray *)paths{
    if (self = [super init]) {
        self.imagePathArray = paths;
        angel = 0;
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
    
    // 刷新频率
    self.preferredFramesPerSecond = 60;
    
    // debuglabel
    self.debugLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20,20,100,30)] autorelease];
    self.debugLabel.backgroundColor = [UIColor clearColor];
    self.debugLabel.textColor = [UIColor whiteColor];
    self.debugLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    self.debugLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.debugLabel];
    
    // GL渲染容器层
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    
    // GL初始化配置
    [self setupGL];
    
    // 设置Size
    [self changeSize:self.view.frame.size];
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
        if (i % 2 == 0) {
            // 偶数位翻转
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4);
            // 左半边三角形
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, -1.0f);
            paperBatchs[i].Vertex3f(0, 1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, -1.0f);
            paperBatchs[i].Vertex3f(0, -1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, -1.0f);
            paperBatchs[i].Vertex3f(1.0f, 1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, -1.0f);
            paperBatchs[i].Vertex3f(1.0f, -1.0f, 0);
            paperBatchs[i].End();
        }else{
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4);
            // 左半边三角形
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, 1.0f);
            paperBatchs[i].Vertex3f(0, 1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, 1.0f);
            paperBatchs[i].Vertex3f(0, -1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, 1.0f);
            paperBatchs[i].Vertex3f(1.0f, 1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(0, 0, 1.0f);
            paperBatchs[i].Vertex3f(1.0f, -1.0f, 0);
            paperBatchs[i].End();
        }
    }
}

- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    viewFrame.Normalize();
    viewFrame.MoveForward(-5.0f);
    
    // 渲染图形
    [self createPaperBatchArray];
    
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
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    /************************准备开整**************************/
    // 相机位置
    M3DMatrix44f mCamera;
    viewFrame.GetCameraMatrix(mCamera);
    modelViewMatix.PushMatrix(mCamera);
    
    angel = angel - 1;
    if (angel <= -360) {
        angel = 0;
    }
    
    const float *tempM;
    tempM =  transformPipeline.GetModelViewMatrix();
    for (int i = 0; i < 16; i++) {
        NSLog(@"%f",tempM[i]);
    }
    
    self.debugLabel.text = [NSString stringWithFormat:@"%d f/s",self.framesPerSecond];
    
    modelViewMatix.Rotate(angel, 0.0f, 1.0f, 0.0f);
    GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
    GLfloat vLightPos[] = {0.0f, 0.0f, 1.0f};
    for (int i = 0; i < self.imagePathArray.count; i++) {
        if (i!=0) {
            modelViewMatix.Rotate(-10, 0.0, 1.0f, 0.0f);
        }
        
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(),vLightPos, vRed);
        paperBatchs[i].Draw();
    }
    
    modelViewMatix.PopMatrix();
}

#pragma mark -
#pragma mark Rotation
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self changeSize:self.view.frame.size];
}

@end

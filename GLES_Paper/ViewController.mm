//
//  ViewController.m
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

#import "ViewController.h"
#import "Define.h"

#define PAPER_FRAMESPERSECOND     60                // 刷新频率
#define PAPER_MIN_ANGLE           (M_PI_4/4)            // 书页夹角/2
#define PAPER_MAX_ANGLE           M_PI_4              // (展开书页夹角 - 书页夹角)/2
#define PAPER_Z_DISTANCE          (-5.0f)           // 沿z轴距离
#define PAPER_Z_MIN_DISTANCE      1.0f              // 最小z轴距离
#define PAPER_Z_MAX_DISTANCE      (-10.0f)          // 最大z轴距离
#define PAPER_PERSPECTIVE_NEAR    1.0f              // 透视场近端
#define PAPER_PERSPECTIVE_FAR     1000.0f           // 透视场远端
#define PAPER_PERSPECTIVE_FOVY    35.0f
#define PAPER_ROTATION_RADIUS     0.3f              // 整体的大圆圈的旋转半径

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
    
	// 设置viewPort
    glViewport(0, 0, size.width, size.height);
    
    // 设置投影透视
    viewFrustum.SetPerspective(PAPER_PERSPECTIVE_FOVY, float(size.width)/float(size.height), PAPER_PERSPECTIVE_NEAR, PAPER_PERSPECTIVE_FAR);
    
    // 加载透视投影矩阵
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    // 变换管线
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
    self.preferredFramesPerSecond = PAPER_FRAMESPERSECOND;
    
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
    view.drawableMultisample = GLKViewDrawableMultisampleNone;
    
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
            // 奇数位翻转
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
            // 右半边三角形
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
    viewFrame.MoveForward(PAPER_Z_DISTANCE);
    
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
    
    
    angel = angel - 0.01;
    if (angel < - M_PI * 2) {
        angel = 0;
    }
    
    // 奇数旋转-PAPER_MIN_ANGLE；偶数旋转PAPER_MIN_ANGLE
    for (int i = 0; i < self.imagePathArray.count ; i++) {
        
        // 4、照相机机位
        modelViewMatix.PushMatrix(mCamera);
        
        // 3、
        modelViewMatix.Rotate(angel, 0, 1, 0);
        
        // 2、绕y轴旋转
        int count = self.imagePathArray.count/2;
        int index = i/2;
        int num = count - index - 1;
        
        
        float degree0 = 2 * atanf(sinf(PAPER_MIN_ANGLE)/(PAPER_ROTATION_RADIUS + cosf(PAPER_MIN_ANGLE)));
        float degree1 = 2 * atanf(sinf(PAPER_MAX_ANGLE)/(PAPER_ROTATION_RADIUS + cosf(PAPER_MAX_ANGLE)));
        if (index <= self.pageIndex) {
            
        }
        modelViewMatix.Rotate(- num * degree0, 0, 1, 0);

        
        
        // 1、整体沿+x移动 PAPER_ROTATION_RADIUS
        modelViewMatix.Translate(PAPER_ROTATION_RADIUS, 0, 0);
        
        // 0、自身旋转
        if (i % 2 != 0) {
            modelViewMatix.Rotate(PAPER_MIN_ANGLE, 0, 1, 0);
        }else{
            modelViewMatix.Rotate(-PAPER_MIN_ANGLE, 0, 1, 0);
        }
        
        GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
        GLfloat vLightPos[] = {0.0f, 0.0f, 1.0f};
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(),vLightPos, vRed);
        paperBatchs[i].Draw();
        
        modelViewMatix.PopMatrix();
    }
    
    self.debugLabel.text = [NSString stringWithFormat:@"%d f/s",self.framesPerSecond];
}

#pragma mark -
#pragma mark Rotation
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self changeSize:self.view.frame.size];
}

@end

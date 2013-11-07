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
#define PAPER_MIN_ANGLE           (M_PI_4/6)            // 书页夹角/2
#define PAPER_MAX_ANGLE           (M_PI_4)              // (展开书页夹角 - 书页夹角)/2
#define PAPER_Z_DISTANCE          (-3.0f)           // 沿z轴距离
#define PAPER_Z_MIN_DISTANCE      1.0f              // 最小z轴距离
#define PAPER_Z_MAX_DISTANCE      (-10.0f)          // 最大z轴距离
#define PAPER_PERSPECTIVE_NEAR    1.0f              // 透视场近端
#define PAPER_PERSPECTIVE_FAR     20.0f           // 透视场远端
#define PAPER_PERSPECTIVE_FOVY    60.0f
#define PAPER_ROTATION_RADIUS     0.3f              // 整体的大圆圈的旋转半径
#define PAPER_X_DISTANCE          sinf(PAPER_MIN_ANGLE) // 沿x轴距离
#define PAPER_RADIUS              (2 * PAPER_X_DISTANCE)



@interface ViewController () {
    
}
@property (nonatomic,retain) NSArray *imagePathArray;        // 图片地址
@property (retain, nonatomic) EAGLContext *context;
@property (nonatomic,retain) UILabel *debugLabel;
@property (nonatomic,assign) PaperStatus paperStatus;           // 书页的当前状态(PaperNormal,PaperUnfold,PaperFold)

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

- (void)tearDownGL{
    // clear gl 
    [EAGLContext setCurrentContext:self.context];
    
    // delete shaders
    glDeleteProgram(paperFlatLightShader.shaderId);
    glDeleteProgram(backgroundFlatLightShader.shaderId);
    glDeleteProgram(shadowDepthShader.shaderId);
    
    // delete textures
    glDeleteTextures(1, &paperTexture);
    glDeleteTextures(1, &shadowTexture);
    
    // delete FBO
    glDeleteFramebuffers(1,&shadowBuffer);
    
    // delete batchs
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
    }
}


- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    [self initShaders];
    
    /* 准备纹理 */
    // 图片纹理
    [self loadTextureWithId:&paperTexture imageFilePath:[[NSBundle mainBundle] pathForResource:@"sex" ofType:@"png"]];
    // 阴影纹理和FBO
    [self createShadowTexture];
    
    // 准备渲染图形的批次
    [self createPaperBatchArray];       // papers
    [self createBackgroundBatch];
}

- (id) initWithImagePaths:(NSArray *)paths{
    if (self = [super init]) {
        self.imagePathArray = paths;
        angel = 0;
    }
    return self;
}

-(void) changeSize:(CGSize)size{
    frameSize = CGSizeMake(size.width, size.height);
    // 准备数据
    paningMove.moveSensitivity = frameSize.width/2;
    pinchMove.pinchSensitivity =  frameSize.width/2;
    
	// Prevent a divide by zero
	if(size.height == 0)
		size.height = 1;
    
    NSLog(@"width:%f,height:%f",size.width,size.height);
    
	// 设置viewPort
    glViewport(0, 0, size.width, size.height);
    
    // 书页
    paperPipeline.viewFrustum.SetPerspective(PAPER_PERSPECTIVE_FOVY, 1.0, PAPER_PERSPECTIVE_NEAR, PAPER_PERSPECTIVE_FAR);
    paperPipeline.projectionMatrix.LoadMatrix(paperPipeline.viewFrustum.GetProjectionMatrix());
    paperPipeline.transformPipeline.SetMatrixStacks(paperPipeline.modelViewMatrix, paperPipeline.projectionMatrix);
    
    // 背景
    backgroundPipeline.viewFrustum.SetOrthographic(-1, 1, -1, 1, -10, 10);
    backgroundPipeline.projectionMatrix.LoadMatrix(backgroundPipeline.viewFrustum.GetProjectionMatrix());
    backgroundPipeline.transformPipeline.SetMatrixStacks(backgroundPipeline.modelViewMatrix, backgroundPipeline.projectionMatrix);
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.paperStatus = PaperNormal;
    
    
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
    if (([[UIApplication sharedApplication]statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication]statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
        CGSize size = CGSizeMake(SCREEN_HEIGHT,SCREEN_WIDTH);
        [self changeSize:size];
        paningMove.moveSensitivity = size.width;
        pinchMove.pinchSensitivity = paningMove.moveSensitivity;
    }else{
        CGSize size = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
        
        [self changeSize:size];
        paningMove.moveSensitivity = size.width;
        pinchMove.pinchSensitivity = paningMove.moveSensitivity;
    }
    
    // 添加手势
    [self addGesture];
}

- (void) addGesture{
    // 滑动翻页手势
    panGesture = [[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(paningGestureReceive:)]autorelease];
    [self.view addGestureRecognizer:panGesture];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    
    
    // 双指捏合手势
    pinchGesture = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureReceive:)] autorelease];
    [self.view addGestureRecognizer:pinchGesture];
    [pinchGesture requireGestureRecognizerToFail:panGesture];
    
    // 点击手势
    UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureReceive:)] autorelease];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [tapGesture requireGestureRecognizerToFail:panGesture];
}

#pragma mark -
#pragma mark 创建渲染图形的批次
// 创建所有的Paper批次
- (void) createPaperBatchArray{
    // 创建paper批次序列
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
    }
    paperBatchs = new GLBatch[self.imagePathArray.count];
    float z = 1.0f;
    for (int i = 0; i < self.imagePathArray.count; i++) {
        if (i % 2 == 0) {
            // 奇数位翻转
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4,1);
            // 左半边三角形
            paperBatchs[i].MultiTexCoord2f(0, 0.5, 1.0);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, z, 0.0f);
            
            
            paperBatchs[i].MultiTexCoord2f(0, 0.5, 0.0);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, -z, 0);
            
            paperBatchs[i].MultiTexCoord2f(0, 0.0, 1.0);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, z, 1.0f);
            
            paperBatchs[i].MultiTexCoord2f(0, 0.0, 0.0);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, -z, 1.0f);
            paperBatchs[i].End();
        }else{
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4,1);
            // 右半边三角形
            paperBatchs[i].MultiTexCoord2f(0, 0.5, 1.0);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, z, 0);
            
            paperBatchs[i].MultiTexCoord2f(0, 0.5, 0);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, -z, 0);
            
            paperBatchs[i].MultiTexCoord2f(0.0, 1.0, 1.0);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, z, 1.0f);
            
            paperBatchs[i].MultiTexCoord2f(0.0, 1.0, 0.0);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, -z, 1.0f);
            paperBatchs[i].End();
        }
    }
}

// 创建background的批次
- (void) createBackgroundBatch{
    // 创建纹理
    backgroundBatch.Begin(GL_TRIANGLE_FAN, 4,1); // 四个顶点一个纹理
    
    // 左下
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(-1.0f, -1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    
    // 左上
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(-1.0f, 1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
    
    // 右上
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(1.0f, 1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(0, 1.0f, 1.0f);

    // 右下
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(1.0f, -1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    
    backgroundBatch.End();
}

#pragma mark -
#pragma mark 创建绘图所需的纹理
- (void) loadTextureWithId:(GLuint *)textureId imageFilePath:(NSString *)filePath{
    glGenTextures(1, textureId);
    glBindTexture(GL_TEXTURE_2D, *textureId);
    
    // 环绕模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // 过滤模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    NSData *texData = [[NSData alloc] initWithContentsOfFile:filePath];
    UIImage *image = [[UIImage alloc] initWithData:texData];
    if (image == nil)
        NSLog(@"Do real error checking here");
    
    GLuint width = CGImageGetWidth(image.CGImage);
    GLuint height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(height * width * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    
    free(imageData);
    [image release];
    [texData release];
}

// 构造阴影纹理
- (void) createShadowTexture{
    glGenTextures(1, &shadowTexture);
    
    glBindTexture(GL_TEXTURE_2D, shadowTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    
    // we do not want to wrap, this will cause incorrect shadows to be rendered
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // create or reuse the depth texture
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, frameSize.width, frameSize.height, 0, GL_RG_EXT, GL_HALF_FLOAT_OES, 0);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    // unbind it for now
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // create a framebuffer object to attach the depth texture to
    glGenFramebuffers(1, &shadowBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, shadowBuffer);
    
    // attach the depth texture to the render buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, shadowTexture, 0);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"error creating shadow FBO, status code 0x%4X", status);
    
    // unbind the FBO
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}


// 构造需要的着色器
- (void) initShaders{
    
    // paper shader
    const char *vp = [[[NSBundle mainBundle] pathForResource:@"PaperFlatLight" ofType:@"vsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *fp = [[[NSBundle mainBundle] pathForResource:@"PaperFlatLight" ofType:@"fsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    paperFlatLightShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp, 3, GLT_ATTRIBUTE_VERTEX, "vVertex",GLT_ATTRIBUTE_NORMAL, "vNormal",GLT_ATTRIBUTE_TEXTURE0,"vTexCoord");
    

	paperFlatLightShader.mvpMatrix = glGetUniformLocation(paperFlatLightShader.shaderId, "mvpMatrix");
	paperFlatLightShader.mvMatrix  = glGetUniformLocation(paperFlatLightShader.shaderId, "mvMatrix");
	paperFlatLightShader.normalMatrix  = glGetUniformLocation(paperFlatLightShader.shaderId, "normalMatrix");
    paperFlatLightShader.radiusZ = glGetUniformLocation(paperFlatLightShader.shaderId, "radiusZ");
    paperFlatLightShader.radiusY = glGetUniformLocation(paperFlatLightShader.shaderId, "radiusY");
    paperFlatLightShader.backHide = glGetUniformLocation(paperFlatLightShader.shaderId, "backHide");
    paperFlatLightShader.lightColor = glGetUniformLocation(paperFlatLightShader.shaderId, "lightColor");
    paperFlatLightShader.lightPosition = glGetUniformLocation(paperFlatLightShader.shaderId, "lightPosition");
    paperFlatLightShader.leftHalf = glGetUniformLocation(paperFlatLightShader.shaderId, "leftHalf");
    paperFlatLightShader.colorMap = glGetUniformLocation(paperFlatLightShader.shaderId, "colorMap");
    paperFlatLightShader.fovy = glGetUniformLocation(paperFlatLightShader.shaderId, "fovy");
    paperFlatLightShader.z0 = glGetUniformLocation(paperFlatLightShader.shaderId, "z0");
    paperFlatLightShader.z1 = glGetUniformLocation(paperFlatLightShader.shaderId, "z1");
    
    // background shader
    vp = [[[NSBundle mainBundle] pathForResource:@"BackgroundFlatLight" ofType:@"vsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    fp = [[[NSBundle mainBundle] pathForResource:@"BackgroundFlatLight" ofType:@"fsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    backgroundFlatLightShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp,3,GLT_ATTRIBUTE_VERTEX,"vVertex",GLT_ATTRIBUTE_NORMAL,"vNormal",GLT_ATTRIBUTE_TEXTURE0,"vTexCoord");
    
    backgroundFlatLightShader.mvpMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvpMatrix");
    backgroundFlatLightShader.mvMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvMatrix");
    backgroundFlatLightShader.normalMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "normalMatrix");
    backgroundFlatLightShader.lightPosition = glGetUniformLocation(backgroundFlatLightShader.shaderId, "vLightPosition");
    backgroundFlatLightShader.ambientColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "ambientColor");
    backgroundFlatLightShader.diffuseColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "diffuseColor");
    backgroundFlatLightShader.colorMap = glGetUniformLocation(backgroundFlatLightShader.shaderId, "colorMap");
    
    // shadowdepth shader
    shadowDepthShader.mvpMatrix = glGetUniformLocation(shadowDepthShader.shaderId, "mvpMatrix");
}


#pragma mark - 
#pragma mark 绘图

// 绘制背景
- (void) drawBackground{
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    backgroundPipeline.modelViewMatrix.PushMatrix();
    backgroundPipeline.modelViewMatrix.Translate(0, 0, -7);
    
    // 绑定着色器
    glUseProgram(backgroundFlatLightShader.shaderId);
    
    // 传递数据给着色器
    GLfloat vAmbientColor[] = { 0.1f, 0.1f, 0.1f, 1.0f };   // 环境光
    GLfloat vDiffuseColor[] = { 0.5f, 0.54f, 0.54f, 1.0f };   // 散射光
    
    GLfloat vLightPos[] = {0.0f, 0.0f, -5.6f};
    glUniform4fv(backgroundFlatLightShader.ambientColor, 1, vAmbientColor);
    glUniform4fv(backgroundFlatLightShader.diffuseColor, 1, vDiffuseColor);
    glUniform3fv(backgroundFlatLightShader.lightPosition, 1, vLightPos);
    glUniformMatrix4fv(backgroundFlatLightShader.mvpMatrix, 1, GL_FALSE, backgroundPipeline.transformPipeline.GetModelViewProjectionMatrix());
    glUniformMatrix4fv(backgroundFlatLightShader.mvMatrix, 1, GL_FALSE, backgroundPipeline.transformPipeline.GetModelViewMatrix());
    glUniformMatrix3fv(backgroundFlatLightShader.normalMatrix, 1, GL_FALSE, backgroundPipeline.transformPipeline.GetNormalMatrix());
    
    //glUniform1f(backgroundFlatLightShader.colorMap, 0);
    
    // 纹理
    //glBindTexture(GL_TEXTURE_2D, self.varianceShadowBuffer.texture);
    
    backgroundBatch.Draw();
    
    backgroundPipeline.modelViewMatrix.PopMatrix();
}

// 绘制所有的书页
- (void) drawPapersLookAt:(M3DMatrix44f)lookAt shadow:(BOOL)shadow{

    angel = angel - 0.01;
    if (angel < - M_PI * 2) {
        angel = 0;
    }
    
    float x = paningMove.x;
    float y = (-cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS) + sqrtf((cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS)) * (cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS)) - 4 * (x * x - 2 * PAPER_RADIUS * x)))/2;
    float theta = asinf(y * sinf(M_PI - 2 * PAPER_MAX_ANGLE)/PAPER_RADIUS);
    
    
    // 奇数旋转-PAPER_MIN_ANGLE；偶数旋转PAPER_MIN_ANGLE
    for (int i = 0; i < self.imagePathArray.count ; i++) {
        
        // 4、照相机机位
        paperPipeline.modelViewMatrix.PushMatrix(lookAt);
        paperPipeline.modelViewMatrix.Translate(0, 0, PAPER_Z_DISTANCE + pinchMove.zMove);
        
        
        // 3、
        //paperPipeline.modelViewMatrix.Rotate(angel, 0, 1, 0);
        
        // 3、绕y轴旋转
        NSInteger index = (i + 1)/2;
        float yRotate = 0;
        if (index <= self.pageIndex) {
            yRotate = -PAPER_MAX_ANGLE + pinchMove.beta;
        }else{
            yRotate = PAPER_MAX_ANGLE - pinchMove.beta;
        }
        paperPipeline.modelViewMatrix.Rotate(yRotate, 0, 1, 0);
        
        // 2、绕固定点旋转
        if (paningMove.nextPageIndex > self.pageIndex) {
            if (index == self.pageIndex + 1) {
                // 2.2
                paperPipeline.modelViewMatrix.Translate(PAPER_RADIUS - x, 0, 0);
                // 2.1
                paperPipeline.modelViewMatrix.Rotate(-theta, 0, 1, 0);
                // 2.0
                paperPipeline.modelViewMatrix.Translate(-(PAPER_RADIUS - x), 0, 0);
            }
        }else{
            if (index == self.pageIndex) {
                // 2.2
                paperPipeline.modelViewMatrix.Translate(-(PAPER_RADIUS - x), 0, 0);
                // 2.1
                paperPipeline.modelViewMatrix.Rotate(theta, 0, 1, 0);
                // 2.0
                paperPipeline.modelViewMatrix.Translate(PAPER_RADIUS - x, 0, 0);
            }
        }
        
        // 1、整体沿+x移动 PAPER_X_DISTANCE
        index = i/2;
        NSInteger tindex = (i + 1)/2;
        float xDistance = 0;
        xDistance = (index - self.pageIndex) * 2 * sinf(PAPER_MIN_ANGLE - pinchMove.theta);
        if (paningMove.nextPageIndex > self.pageIndex) {
            if (tindex <= self.pageIndex ) {
                xDistance = xDistance - y;
            }else{
                xDistance = xDistance - x;
            }
            
        }else{
            if (tindex <= self.pageIndex) {
                xDistance = xDistance + x;
            }else{
                xDistance = xDistance + y;
            }
        }
        
        
        paperPipeline.modelViewMatrix.Translate(xDistance, 0, 0);
        
        // 0、自身旋转
        if (i % 2 != 0) {
            paperPipeline.modelViewMatrix.Rotate(PAPER_MIN_ANGLE - pinchMove.theta, 0, 1, 0);
        }else{
            paperPipeline.modelViewMatrix.Rotate(-PAPER_MIN_ANGLE + pinchMove.theta, 0, 1, 0);
        }
        
        if (shadow) {
            // 启用阴影深度着色器
            glUseProgram(shadowDepthShader.shaderId);
            glUniformMatrix4fv(shadowDepthShader.mvpMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetModelViewProjectionMatrix());
            paperBatchs[i].Draw();
        }else{
            // 启用书页光照着色器
            GLfloat vDiffuseColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };
            GLfloat vLightPosition[] = { 0.0, 0.0, 5.0};
            glUseProgram(paperFlatLightShader.shaderId);
            glUniformMatrix4fv(paperFlatLightShader.mvpMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetModelViewProjectionMatrix());
            glUniformMatrix4fv(paperFlatLightShader.mvMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetModelViewMatrix());
            glUniformMatrix3fv(paperFlatLightShader.normalMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetNormalMatrix());
            glUniform1f(paperFlatLightShader.radiusZ, 0.06);
            glUniform1f(paperFlatLightShader.radiusY, 0.06 * frameSize.width/frameSize.height);
            if (i == 0 || i == self.imagePathArray.count - 1) {
                glUniform1i(paperFlatLightShader.backHide, 0);
            }else{
                glUniform1i(paperFlatLightShader.backHide, 1);
            }
            glUniform4fv(paperFlatLightShader.lightColor, 1, vDiffuseColor);
            glUniform3fv(paperFlatLightShader.lightPosition, 1, vLightPosition);
            if (i % 2 == 0) {
                glUniform1i(paperFlatLightShader.leftHalf, 1);
            }else{
                glUniform1i(paperFlatLightShader.leftHalf, 0);
            }
            glUniform1f(paperFlatLightShader.fovy, m3dDegToRad(PAPER_PERSPECTIVE_FOVY));
            glUniform1f(paperFlatLightShader.z0, (-PAPER_Z_DISTANCE) - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY)));
            glUniform1f(paperFlatLightShader.z1, 5.0 - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY)));
            glUniform1f(paperFlatLightShader.colorMap, 0);
            
            // 纹理
            glBindTexture(GL_TEXTURE_2D, paperTexture);
            
            paperBatchs[i].Draw();
        }
        
        paperPipeline.modelViewMatrix.PopMatrix();
    }
}
- (void) drawPapers{
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    //return;
    
    M3DMatrix44f lookAt;
    m3dLoadIdentity44(lookAt);
    [self drawPapersLookAt:lookAt shadow:NO];
}

// 绘制书页投影
- (void) drawShadows{
    // 将视点移动到光源位置，绘制投影
    glBindFramebuffer(GL_FRAMEBUFFER, shadowBuffer);
    glViewport(0, 0, frameSize.width, frameSize.height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // create the projection matrix from the cameras view
    static const GLKVector3 kLightPosition = {0.0, 1.0, 0.0 };      // 观察点
    static const GLKVector3 kLightLookAt = { 0.0, 0.0, -0.5 };     // 中心点
    GLKMatrix4 cameraViewMatrix = GLKMatrix4MakeLookAt(kLightPosition.x, kLightPosition.y, kLightPosition.z, kLightLookAt.x, kLightLookAt.y, kLightLookAt.z, 0, 1, 0);
    [self drawPapersLookAt:cameraViewMatrix.m shadow:YES];
 
    
    /* 对阴影进行动态模糊 */ 
    static const GLfloat vertices[] = {-1, -1, 0, 1, -1, 0, -1, 1, 0, 1, 1, 0};
    static const GLfloat textureCoords[] = {0, 0, 1, 0, 0, 1, 1, 1};
    
    // get the current bound FBO and viewport size
    GLint oldFBO;
    GLint viewport[4];
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &oldFBO);
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    // switch to the blur shader
    glUseProgram(self.shader.program);
    
    // set the viewport to use the whole pixel buffer
    glViewport(0, 0, self.size.width, self.size.height);
    
    // enable the vertex attributes
    glEnableVertexAttribArray(BlurShaderPositionAttribute);
    glVertexAttribPointer(BlurShaderPositionAttribute, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(BlurShaderTexCoordAttribute);
    glVertexAttribPointer(BlurShaderTexCoordAttribute, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);
    
    // bind the texture to blur
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(self.shader.sampler, 0);
    
    // set the filter weights and offset steps
    glUniform1fv(self.shader.filterOffsets, 3, kFilterOffsets);
    glUniform1fv(self.shader.filterWeights, 3, kFilterWeights);
    glUniform2f(self.shader.pixelStep, 0, 1.0 / self.size.height);
    
    // blur in the horizontal direction into the bounce buffer
    glBindFramebuffer(GL_FRAMEBUFFER, _bounceFBO);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // now blur in the vertical direction back into the original buffer
    glBindFramebuffer(GL_FRAMEBUFFER, oldFBO);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindTexture(GL_TEXTURE_2D, _bounceTex);
    glUniform2f(self.shader.pixelStep, 1.0 / self.size.width, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // cleanup
    glDisableVertexAttribArray(BlurShaderPositionAttribute);
    glDisableVertexAttribArray(BlurShaderTexCoordAttribute);
    glUseProgram(0);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    glBindFramebuffer(GL_FRAMEBUFFER, oldFBO);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 重置变换
    [self resetViewsTimes:0.3];
    
    // Unfold
    [self unfoldViewsTimes:0.3];
    
    // normal
    [self normalViewsTimes:0.3];
    
    // 清理画布
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    // 清除颜色缓冲区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    // 启用颜色抖动
    glEnable(GL_DITHER);
    
    /************************准备开整**************************/
    
    // 在缓冲区绘制阴影
    [self drawShadows];
    
    // 绘制背景
    [self drawBackground];
    
    // 绘制书页
    [self drawPapers];
    
    
    self.debugLabel.text = [NSString stringWithFormat:@"%d f/s",self.framesPerSecond];
}


#pragma mark -
#pragma mark PanMove & PinchMove
- (float) touchLengthMoveTo:(CGPoint)touchPoint{
    return -touchPoint.x + paningMove.startTouch.x;
}

- (float) pinchLengthMoveTo:(CGPoint)touchPoint0 anotherPoint:(CGPoint)touchPoint1{
    float x0 = ABS(pinchMove.pinchTouch0.x - pinchMove.pinchTouch1.x);
    float x1 =  ABS(touchPoint0.x - touchPoint1.x);
    return x1 - x0;
}

#pragma mark -
#pragma mark MoveChange

// 单手滑动
- (void) moveChange:(float)move{
    NSInteger currentIndex = paningMove.startPageIndex + (int)(move/paningMove.moveSensitivity);
    if (currentIndex < 0 || currentIndex >= self.imagePathArray.count/2) {
        return;
    }
    
    // 当前页面的值
    self.pageIndex = currentIndex;
    
  
    if (move > 0) {
        paningMove.pageRemainder = move - paningMove.moveSensitivity * ((int)(move/paningMove.moveSensitivity));
        if (paningMove.pageRemainder > paningMove.moveSensitivity/2) {
            currentIndex++;
        }
    }else if(move < 0){
        paningMove.pageRemainder = (-move) + paningMove.moveSensitivity * ((int)(move/paningMove.moveSensitivity));
        if (paningMove.pageRemainder > paningMove.moveSensitivity/2) {
            currentIndex--;
        }
    }
    
    // 变换曲线 y= x * x 减慢起始速度
    paningMove.pageRemainder = paningMove.pageRemainder * paningMove.pageRemainder/paningMove.moveSensitivity;
    
    // 下一页的预测值
    paningMove.nextPageIndex = move > 0 ? (self.pageIndex + 1):(self.pageIndex - 1);
    
    paningMove.x = PAPER_RADIUS * paningMove.pageRemainder/paningMove.moveSensitivity;
}

#pragma mark -
#pragma mark PinchChange
// 捏合运动
- (void) pinchChange:(float)move{
    if(self.paperStatus == PaperUnfold){
        if (move < 0) {
            move = -move;
            if (move < pinchMove.pinchSensitivity) {
                pinchMove.theta = 0;
                pinchMove.beta =  (PAPER_MIN_ANGLE - PAPER_MAX_ANGLE) * (1 - MIN(1.0, move/pinchMove.pinchSensitivity));
                pinchMove.zMove = (abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY)))  * (1 - MIN(1.0, move/pinchMove.pinchSensitivity));
            }else{
                move = move - pinchMove.pinchSensitivity;
                pinchMove.theta = PAPER_MIN_ANGLE * MIN(1.0-0.04,move/pinchMove.pinchSensitivity);
                pinchMove.beta = PAPER_MAX_ANGLE * MIN(1.0-0.1, move/pinchMove.pinchSensitivity);
                pinchMove.zMove = -1 * MIN(1.0, move/pinchMove.pinchSensitivity);
            }
        }else{
            pinchMove.zMove = (abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY))) +  (tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY)) - 1.4) * MIN(1.0, move/pinchMove.pinchSensitivity);
        }
    }else if(self.paperStatus == PaperNormal){
        if (move < 0) {
            move = -move;
            pinchMove.theta = PAPER_MIN_ANGLE * MIN(1.0-0.04,move/pinchMove.pinchSensitivity);
            pinchMove.beta = PAPER_MAX_ANGLE * MIN(1.0-0.1, move/pinchMove.pinchSensitivity);
            pinchMove.zMove = -1 * MIN(1.0, move/pinchMove.pinchSensitivity);
        }else{
            pinchMove.theta = 0;
            pinchMove.beta = (PAPER_MIN_ANGLE - PAPER_MAX_ANGLE) * MIN(1.0, move/pinchMove.pinchSensitivity);
            pinchMove.zMove = (abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY)))  * MIN(1.0, move/pinchMove.pinchSensitivity);
        }
    }
}

#pragma mark -
#pragma mark ResetViews

- (void) unfoldViewsTimes:(float)time{
    if (pinchMove.needUnfold) {
        if (pinchMove.currentTime == 0.0) {
            pinchMove.currentTime = stopWatch.GetElapsedSeconds();
            pinchMove.currentBeta = pinchMove.beta;
            pinchMove.currentTheta = pinchMove.theta;
            pinchMove.currentZMove = pinchMove.zMove;
        }
        CFTimeInterval timeOffset = stopWatch.GetElapsedSeconds() - pinchMove.currentTime;
        if (timeOffset > time) {
            self.paperStatus = PaperUnfold;
            panGesture.enabled = NO;
            pinchMove.needUnfold = NO;
            pinchMove.currentTime = 0.0;
            pinchMove.beta = -(PAPER_MAX_ANGLE - PAPER_MIN_ANGLE);
            pinchMove.zMove = abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(60));
            pinchMove.theta = 0.0f;
        }else{
            float betaS = pinchMove.currentBeta - (-(PAPER_MAX_ANGLE - PAPER_MIN_ANGLE));
            float zMoveS = pinchMove.currentZMove -  (abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(60)));
            float thetaS = pinchMove.currentTheta;
            
            float betaV0 = 2 * betaS/time;
            float zMoveV0 = 2 * zMoveS/time;
            float thetaV0 = 2 * thetaS/time;
            
            pinchMove.accelerationTheta = 2 * thetaS/(time * time);
            pinchMove.accelerationBeta = 2 * betaS/(time * time);
            pinchMove.accelerationZ = 2 * zMoveS/(time * time);
            
            
            pinchMove.theta = pinchMove.currentTheta - (thetaV0 * timeOffset - pinchMove.accelerationTheta * timeOffset * timeOffset/2);
            pinchMove.beta = pinchMove.currentBeta - (betaV0 * timeOffset - pinchMove.accelerationBeta * timeOffset * timeOffset/2);
            pinchMove.zMove = pinchMove.currentZMove - (zMoveV0 * timeOffset - pinchMove.accelerationZ * timeOffset * timeOffset/2);
        }
    }
}

- (void) normalViewsTimes:(float)time{
    if (pinchMove.needNormal) {
        if (pinchMove.currentTime == 0.0) {
            pinchMove.currentTime = stopWatch.GetElapsedSeconds();
            pinchMove.currentBeta = pinchMove.beta;
            pinchMove.currentTheta = pinchMove.theta;
            pinchMove.currentZMove = pinchMove.zMove;
        }
        CFTimeInterval timeOffset = stopWatch.GetElapsedSeconds() - pinchMove.currentTime;
        if (timeOffset > time) {
            panGesture.enabled = YES;
            self.paperStatus = PaperNormal;
            pinchMove.needNormal = NO;
            pinchMove.currentTime = 0.0;
            pinchMove.beta = 0.0f;
            pinchMove.theta = 0.0f;
            pinchMove.zMove = 0.0f;
        }else{
            float thetaS = pinchMove.currentTheta;
            float thetaV0 = 2 * thetaS / time;
            pinchMove.accelerationTheta = 2 * thetaS/(time * time);
            
            float betaS = pinchMove.currentBeta;
            float betaV0 = 2 * betaS / time;
            pinchMove.accelerationBeta = 2 * betaS/(time * time);
            
            float zMoveS = pinchMove.currentZMove;
            float zMoveV0 = 2 * zMoveS / time;
            pinchMove.accelerationZ = 2 * zMoveS/(time * time);
            
            pinchMove.theta = pinchMove.currentTheta - (thetaV0 * timeOffset - pinchMove.accelerationTheta * timeOffset * timeOffset/2);
            pinchMove.beta = pinchMove.currentBeta - (betaV0 * timeOffset - pinchMove.accelerationBeta * timeOffset * timeOffset/2);
            pinchMove.zMove = pinchMove.currentZMove - (zMoveV0 * timeOffset - pinchMove.accelerationZ * timeOffset * timeOffset/2);
        }
    }
}

- (void) resetViewsTimes:(float)time{
    if (paningMove.needReset) {
        if (paningMove.currentTime == 0.0) {
            paningMove.currentTime = stopWatch.GetElapsedSeconds();
            paningMove.currentX = paningMove.x;
        }
        CFTimeInterval timeOffset = stopWatch.GetElapsedSeconds() - paningMove.currentTime;
        if (timeOffset > time) {
            paningMove.needReset = NO;
            paningMove.currentTime = 0.0;
            if (paningMove.currentX < PAPER_RADIUS * 0.02) {
                paningMove.x = 0;
            }else{
                paningMove.x = 0;
                if (paningMove.nextPageIndex >= 0 && paningMove.nextPageIndex < self.imagePathArray.count/2) {
                    self.pageIndex = paningMove.nextPageIndex;
                }
            }
        }else{
            // s = v0 * t - (1/2) * a * t * t; 减速运动
            if (paningMove.currentX < PAPER_RADIUS*0.02) {
                float s = paningMove.currentX;
                float v0 = 2 * s /time;
                paningMove.acceleration = 2 * s/(time * time);
                paningMove.x = paningMove.currentX - (v0 * timeOffset - paningMove.acceleration * timeOffset * timeOffset/2);
            }else{
                if (paningMove.nextPageIndex < 0 || paningMove.nextPageIndex >= self.imagePathArray.count/2) {
                    float s = paningMove.currentX;
                    float v0 = 2 * s /time;
                    paningMove.acceleration = 2 * s/(time * time);
                    paningMove.x = paningMove.currentX - (v0 * timeOffset - paningMove.acceleration * timeOffset * timeOffset/2);
                }else{
                    float s = paningMove.currentX - PAPER_RADIUS;
                    float v0 = 2 * s / time;
                    paningMove.acceleration = 2 * s/(time * time);
                    paningMove.x = paningMove.currentX - (v0 * timeOffset - paningMove.acceleration * timeOffset * timeOffset/2);
                }
            }
        }
    }
}

#pragma mark -
#pragma mark GestureReceive
// 点击
- (void) tapGestureReceive:(UITapGestureRecognizer *)recoginzer{
    if (self.paperStatus == PaperUnfold) {
        pinchMove.needNormal = YES;
    }else if(self.paperStatus == PaperNormal){
        pinchMove.needUnfold = YES;
    }
}


// 滑动
- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer{
    if (pinchMove.isPinching || self.paperStatus == PaperFold) {
        return;
    }
    // begin paning 显示last screenshot
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        if (self.paperStatus == PaperUnfold) {
            paningMove.needReset = YES;
            return;
        }
        paningMove.endTouch = [recoginzer locationOfTouch:0 inView:self.view];
        paningMove.startTouch = paningMove.endTouch;
        paningMove.startPageIndex = self.pageIndex;
        paningMove.isMoving = YES;
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        paningMove.needReset = YES;
        paningMove.isMoving = NO;
        return;
        // cancal panning 回弹
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        paningMove.needReset = YES;
        paningMove.isMoving = NO;
        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        paningMove.endTouch = [recoginzer locationOfTouch:0 inView:self.view];
        if (paningMove.isMoving) {
            float move = [self touchLengthMoveTo:paningMove.endTouch];
            [self moveChange:move];
        }
    }
}

// 捏合
- (void) pinchGestureReceive:(UIPinchGestureRecognizer *)recoginzer{
    
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        // 限制为双指操作
        if ([recoginzer numberOfTouches] <= 1) {
            return;
        }
        
        pinchMove.isPinching = YES;
        pinchMove.pinchTouch0 = [recoginzer locationOfTouch:0 inView:self.view];
        pinchMove.pinchTouch1 = [recoginzer locationOfTouch:1 inView:self.view];
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        pinchMove.isPinching = NO;
        
        if (self.paperStatus == PaperNormal) {
            if(pinchMove.scope > pinchMove.pinchSensitivity * 0.1){
                // 展开
                pinchMove.needUnfold = YES;
            }else{
                // 还原
                pinchMove.needNormal = YES;
            }
        }else if(self.paperStatus == PaperUnfold){
            if (pinchMove.scope < pinchMove.pinchSensitivity * 0.1) {
                // 还原
                pinchMove.needNormal = YES;
            }else{
                // 展开
                pinchMove.needUnfold = YES;
            }
        }
        return;
        // cancal panning 回弹
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        pinchMove.isPinching = NO;
        //[self resetViewsAnimated:startTouch time:0.3];

        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        // 限制为双指操作
        if ([recoginzer numberOfTouches] <= 1) {
            return;
        }
        if (pinchMove.isPinching) {
            pinchMove.scope = 0;
            CGPoint touch0 = [recoginzer locationOfTouch:0 inView:self.view];
            CGPoint touch1 = [recoginzer locationOfTouch:1 inView:self.view];
            
            pinchMove.scope = [self pinchLengthMoveTo:touch0 anotherPoint:touch1];
            
            [self pinchChange:pinchMove.scope];
        }
    }
}

#pragma mark -
#pragma mark Rotation
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        CGSize size = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
        
        [self changeSize:size];
    }else{
        CGSize size = CGSizeMake(SCREEN_HEIGHT,SCREEN_WIDTH);
        [self changeSize:size];
    }
    
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    
}

@end

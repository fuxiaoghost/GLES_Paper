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
#define PAPER_MAX_ANGLE           (M_PI_4-M_PI_4/4)              // (展开书页夹角 - 书页夹角)/2
#define PAPER_Z_DISTANCE          (-5.0f)           // 沿z轴距离
#define PAPER_Z_MIN_DISTANCE      1.0f              // 最小z轴距离
#define PAPER_Z_MAX_DISTANCE      (-10.0f)          // 最大z轴距离
#define PAPER_PERSPECTIVE_NEAR    1.0f              // 透视场近端
#define PAPER_PERSPECTIVE_FAR     1000.0f           // 透视场远端
#define PAPER_PERSPECTIVE_FOVY    35.0f
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
    // 清理GL的资源
    [EAGLContext setCurrentContext:self.context];
    
    // 删除着色器
    glDeleteProgram(paperFlatLightShader.shaderId);
    glDeleteProgram(backgroundFlatLightShader.shaderId);
    
    // 删除纹理
    glDeleteTextures(1, &backgroundTexture);
    
    // 删除图形批次
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
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
    
    // 准备数据
    moveSensitivity = self.view.frame.size.width;
    pinchSensitivity = moveSensitivity;
    pinchSensitivity_ = 1.0f - pinchSensitivity/2;
    
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
    
    for (int i = 0; i < self.imagePathArray.count; i++) {
        if (i % 2 == 0) {
            // 奇数位翻转
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4);
            // 左半边三角形
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, 1.0f, 0.0f);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, -1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, 1.0f, 1.0f);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(1, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, -1.0f, 1.0f);
            paperBatchs[i].End();
        }else{
            paperBatchs[i].Begin(GL_TRIANGLE_STRIP, 4);
            // 右半边三角形
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, 1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0, -1.0f, 0);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, 1.0f, 1.0f);
            
            paperBatchs[i].Color4f(1.0f, 0.0f, 0.0f, 1.0f);
            paperBatchs[i].Normal3f(-1.0f, 0.0f, 0.0f);
            paperBatchs[i].Vertex3f(0.0f, -1.0f, 1.0f);
            paperBatchs[i].End();
        }
    }
}

// 创建background的批次
- (void) createBackgroundBatch{
    // 创建纹理
    
    backgroundBatch.Begin(GL_TRIANGLE_STRIP, 4);
    
    // 右上
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(1.0f, 1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(backgroundTexture, 1.0f, 1.0f);
    
    // 左上
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(-1.0f, 1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(backgroundTexture, -1.0f, 1.0f);
    
    // 左下
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(-1.0f, -1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(backgroundTexture, -1.0f, -1.0f);
    
    // 右下
    backgroundBatch.Normal3f(0.0f, 0.0f, 1.0f);
    backgroundBatch.Vertex3f(1.0f, -1.0f, 0.0f);
    backgroundBatch.MultiTexCoord2f(backgroundTexture, 1.0f, -1.0f);
    
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
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
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
    CGContextTranslateCTM(context, 0, height - height);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    
    free(imageData);
    [image release];
    [texData release];
}

- (void) createBackgroundTexture{
    [self loadTextureWithId:&backgroundTexture imageFilePath:[[NSBundle mainBundle] pathForResource:@"backgroundTile" ofType:@"png"]];
}

- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    [self initShaders];
    
    // 初始化相机
    viewFrame.Normalize();
    viewFrame.MoveForward(PAPER_Z_DISTANCE);
    
    // 准备纹理
    [self createBackgroundTexture];
    
    // 准备渲染图形的批次
    [self createPaperBatchArray];       // papers
    [self createBackgroundBatch];
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
}

// 构造需要的着色器
- (void) initShaders{
    
    // paper shader
    const char *vp = [[[NSBundle mainBundle] pathForResource:@"PaperFlatLight" ofType:@"vp"] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *fp = [[[NSBundle mainBundle] pathForResource:@"PaperFlatLight" ofType:@"fp"] cStringUsingEncoding:NSUTF8StringEncoding];
    paperFlatLightShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp, 2, GLT_ATTRIBUTE_VERTEX, "vVertex",GLT_ATTRIBUTE_NORMAL, "vNormal");
    
    
	paperFlatLightShader.lightColor = glGetUniformLocation(paperFlatLightShader.shaderId, "diffuseColor");
	paperFlatLightShader.lightPosition = glGetUniformLocation(paperFlatLightShader.shaderId, "vLightPosition");
	paperFlatLightShader.mvpMatrix = glGetUniformLocation(paperFlatLightShader.shaderId, "mvpMatrix");
	paperFlatLightShader.mvMatrix  = glGetUniformLocation(paperFlatLightShader.shaderId, "mvMatrix");
	paperFlatLightShader.normalMatrix  = glGetUniformLocation(paperFlatLightShader.shaderId, "normalMatrix");
    
    // background shader
    vp = [[[NSBundle mainBundle] pathForResource:@"BackgroundFlatLight" ofType:@"vp"] cStringUsingEncoding:NSUTF8StringEncoding];
    fp = [[[NSBundle mainBundle] pathForResource:@"BackgroundFlatLight" ofType:@"fp"] cStringUsingEncoding:NSUTF8StringEncoding];
    backgroundFlatLightShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp,3,GLT_ATTRIBUTE_VERTEX,"vVertex",GLT_ATTRIBUTE_NORMAL,"vNormal",GLT_ATTRIBUTE_TEXTURE0,"vTexture0");
    
    backgroundFlatLightShader.mvpMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvpMatrix");
    backgroundFlatLightShader.mvMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvMatrix");
    backgroundFlatLightShader.normalMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "normalMatrix");
    backgroundFlatLightShader.lightPosition = glGetUniformLocation(backgroundFlatLightShader.shaderId, "vLightPosition");
    backgroundFlatLightShader.ambientColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "ambientColor");
    backgroundFlatLightShader.diffuseColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "diffuseColor");
    backgroundFlatLightShader.specularColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "diffuseColor");
    backgroundFlatLightShader.colorMap = glGetUniformLocation(backgroundFlatLightShader.shaderId, "colorMap");
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void) drawBackground{
    modelViewMatix.PushMatrix();
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    
    // 绑定着色器
    glUseProgram(backgroundFlatLightShader.shaderId);
    
    // 传递数据给着色器
    GLfloat vAmbientColor[] = { 0.2f, 0.2f, 0.2f, 0.2f };   // 环境光
    GLfloat vDiffuseColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };   // 散射光
    GLfloat vSpecularColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };  // 镜面光
    
    GLfloat vLightPos[] = {0.0f, 0.0f, 1.0f};
    glUniform4fv(backgroundFlatLightShader.ambientColor, 1, vAmbientColor);
    glUniform4fv(backgroundFlatLightShader.diffuseColor, 1, vDiffuseColor);
    glUniform4fv(backgroundFlatLightShader.specularColor, 1, vSpecularColor);
    glUniform3fv(backgroundFlatLightShader.lightPosition, 1, vLightPos);
    glUniformMatrix4fv(backgroundFlatLightShader.mvpMatrix, 1, GL_FALSE, transformPipeline.GetModelViewProjectionMatrix());
    glUniformMatrix4fv(backgroundFlatLightShader.mvMatrix, 1, GL_FALSE, transformPipeline.GetModelViewMatrix());
    glUniformMatrix3fv(backgroundFlatLightShader.normalMatrix, 1, GL_FALSE, transformPipeline.GetNormalMatrix());
    
    modelViewMatix.PopMatrix();
}

- (void) drawPapers{
    // 相机位置
    M3DMatrix44f mCamera;
    viewFrame.GetCameraMatrix(mCamera);
    
    
    angel = angel - 0.01;
    if (angel < - M_PI * 2) {
        angel = 0;
    }
    
    
    float y = (-cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS) + sqrtf((cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS)) * (cosf(M_PI - 2 * PAPER_MAX_ANGLE) * (2 * x - 2 * PAPER_RADIUS)) - 4 * (x * x - 2 * PAPER_RADIUS * x)))/2;
    float theta = asinf(y * sinf(M_PI - 2 * PAPER_MAX_ANGLE)/PAPER_RADIUS);
    
    
    // 奇数旋转-PAPER_MIN_ANGLE；偶数旋转PAPER_MIN_ANGLE
    for (int i = 0; i < self.imagePathArray.count ; i++) {
        
        // 4、照相机机位
        modelViewMatix.PushMatrix(mCamera);
        
        // 3、
        //modelViewMatix.Rotate(angel, 0, 1, 0);
        
        // 3、绕y轴旋转
        NSInteger index = (i + 1)/2;
        float yRotate = 0;
        if (index <= self.pageIndex) {
            yRotate = -PAPER_MAX_ANGLE;
        }else{
            yRotate = PAPER_MAX_ANGLE;
        }
        modelViewMatix.Rotate(yRotate, 0, 1, 0);
        
        // 2、绕固定点旋转
        if (nextPageIndex > self.pageIndex) {
            if (index == self.pageIndex + 1) {
                // 2.2
                modelViewMatix.Translate(PAPER_RADIUS - x, 0, 0);
                // 2.1
                modelViewMatix.Rotate(-theta, 0, 1, 0);
                // 2.0
                modelViewMatix.Translate(-(PAPER_RADIUS - x), 0, 0);
            }
        }else{
            if (index == self.pageIndex) {
                // 2.2
                modelViewMatix.Translate(-(PAPER_RADIUS - x), 0, 0);
                // 2.1
                modelViewMatix.Rotate(theta, 0, 1, 0);
                // 2.0
                modelViewMatix.Translate(PAPER_RADIUS - x, 0, 0);
            }
        }
        
        // 1、整体沿+x移动 PAPER_X_DISTANCE
        index = i/2;
        NSInteger tindex = (i + 1)/2;
        float xDistance = 0;
        xDistance = (index - self.pageIndex) * 2 * PAPER_X_DISTANCE;
        if (nextPageIndex > self.pageIndex) {
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
        
    
        
        modelViewMatix.Translate(xDistance, 0, 0);
        
        // 0、自身旋转
        if (i % 2 != 0) {
            modelViewMatix.Rotate(PAPER_MIN_ANGLE, 0, 1, 0);
        }else{
            modelViewMatix.Rotate(-PAPER_MIN_ANGLE, 0, 1, 0);
        }
        
        // 启用着色器
        GLfloat vLightColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };
        GLfloat vLightPos[] = {0.2f, 0.2f, 1.0f};
        glUseProgram(paperFlatLightShader.shaderId);
		glUniform4fv(paperFlatLightShader.lightColor, 1, vLightColor);
		glUniform3fv(paperFlatLightShader.lightPosition, 1, vLightPos);
		glUniformMatrix4fv(paperFlatLightShader.mvpMatrix, 1, GL_FALSE, transformPipeline.GetModelViewProjectionMatrix());
		glUniformMatrix4fv(paperFlatLightShader.mvMatrix, 1, GL_FALSE, transformPipeline.GetModelViewMatrix());
		glUniformMatrix3fv(paperFlatLightShader.normalMatrix, 1, GL_FALSE, transformPipeline.GetNormalMatrix());
        
        paperBatchs[i].Draw();
        
        modelViewMatix.PopMatrix();
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 重置变换
    [self resetViewsTimes:0.3];
    
    
    // 清理画布
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    // 清除颜色缓冲区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    /************************准备开整**************************/
   
    // 绘制基本图形
    [self drawPapers];
    
    self.debugLabel.text = [NSString stringWithFormat:@"%d f/s",self.framesPerSecond];
}


#pragma mark -
#pragma mark PanMove & PinchMove
- (float) touchLengthMoveTo:(CGPoint)touchPoint{
    return -touchPoint.x + startTouch.x;
}

- (float) pinchLengthMoveTo:(CGPoint)touchPoint0 anotherPoint:(CGPoint)touchPoint1{
    float x0 = ABS(pinchTouch0.x - pinchTouch1.x);
    float x1 =  ABS(touchPoint0.x - touchPoint1.x);
    return x1 - x0;
}

#pragma mark -
#pragma mark MoveChange

// 单手滑动
- (void) moveChange:(float)move{
    NSInteger currentIndex = startPageIndex + (int)(move/moveSensitivity);
    if (currentIndex < 0 || currentIndex >= self.imagePathArray.count/2) {
        return;
    }
    
    // 当前页面的值
    self.pageIndex = currentIndex;
    
    float pageRemainder = 0;
    if (move > 0) {
        pageRemainder = move - moveSensitivity * ((int)(move/moveSensitivity));
        if (pageRemainder > moveSensitivity/2) {
            currentIndex++;
        }
    }else if(move < 0){
        pageRemainder = (-move) + moveSensitivity * ((int)(move/moveSensitivity));
        if (pageRemainder > moveSensitivity/2) {
            currentIndex--;
        }
    }
    
    // 变换曲线 y= x * x 减慢起始速度
    pageRemainder = pageRemainder * pageRemainder/moveSensitivity;
    
    // 下一页的预测值
    nextPageIndex = move > 0 ? (self.pageIndex + 1):(self.pageIndex - 1);
    
    x = PAPER_RADIUS * pageRemainder/moveSensitivity;
}

#pragma mark -
#pragma mark PinchChange
// 捏合运动
- (void) pinchChange:(float)move{
}

#pragma mark -
#pragma mark ResetViews

- (void) resetViewsTimes:(float)time{
    if (needReset) {
        if (currentTime == 0) {
            currentTime = stopWatch.GetElapsedSeconds();
            currentX = x;
        }
        CFTimeInterval timeOffset = stopWatch.GetElapsedSeconds() - currentTime;
        if (timeOffset > time) {
            needReset = NO;
            currentTime = 0.0f;
            if (currentX < PAPER_RADIUS * 0.1) {
                x = 0;
            }else{
                x = 0;
                if (nextPageIndex >= 0 && nextPageIndex < self.imagePathArray.count/2) {
                    self.pageIndex = nextPageIndex;
                }
            }
        }else{
            // s = v0 * t - (1/2) * a * t * t; 减速运动
            if (currentX < PAPER_RADIUS*0.1) {
                acceleration = 2 * currentX/(time * time);
                x = currentX - (2 * currentX * timeOffset/time - acceleration * timeOffset * timeOffset/2);
            }else{
                if (nextPageIndex < 0 || nextPageIndex >= self.imagePathArray.count/2) {
                    acceleration = 2 * currentX/(time * time);
                    x = currentX - (2 * currentX * timeOffset/time - acceleration * timeOffset * timeOffset/2);
                }else{
                    acceleration = 2 * (PAPER_RADIUS -currentX)/(time * time);
                    x = currentX + (2 * (PAPER_RADIUS -currentX) * timeOffset/time - acceleration * timeOffset * timeOffset/2);
                }
            }
        }
    }
}

#pragma mark -
#pragma mark GestureReceive
// 点击
- (void) tapGestureReceive:(UITapGestureRecognizer *)recoginzer{
    if (self.paperStatus == PaperUnfold || self.paperStatus == PaperFold) {
        
//        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
//            [self pinchChange:pinchSensitivity/4];
//        } completion:^(BOOL finished) {
//            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
//                [self pinchChange:pinchSensitivity/2];
//            } completion:^(BOOL finished) {
//                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
//                    [self pinchChange:pinchSensitivity* 3/4];
//                } completion:^(BOOL finished) {
//                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
//                        [self resetViews];
//                    } completion:^(BOOL finished) {
//                        
//                    }];
//                }];
//            }];
//        }];
    }else if(self.paperStatus == PaperNormal){
//        [self unfoldAnimated];
    }
}

- (void) preloadImages{
//    float move = [self touchLengthMoveTo:endTouch];
//    float pageRemainder = 0;
//    if (move > 0) {
//        pageRemainder = move - moveSensitivity * ((int)(move/moveSensitivity));
//    }else if(move < 0){
//        pageRemainder = (-move) + moveSensitivity * ((int)(move/moveSensitivity));
//    }
//    if (pageRemainder > moveSensitivity/2) {
//        if (move > 0) {
//            if (self.pageIndex + 1 < self.imageArray.count) {
//                self.pageIndex++;
//            }
//        }else{
//            if (self.pageIndex - 1 >= 0 ) {
//                self.pageIndex--;
//            }
//        }
//    }
}

// 滑动
- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer{
    if (isPinching || self.paperStatus == PaperFold) {
        return;
    }
    // begin paning 显示last screenshot
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        if (self.paperStatus == PaperUnfold) {
            needReset = YES;
            return;
        }
        endTouch = [recoginzer locationOfTouch:0 inView:self.view];
        startTouch = endTouch;
        startPageIndex = self.pageIndex;
        isMoving = YES;
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        needReset = YES;
        isMoving = NO;
        return;
        // cancal panning 回弹
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        needReset = YES;
        isMoving = NO;
        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        endTouch = [recoginzer locationOfTouch:0 inView:self.view];
        if (isMoving) {
            float move = [self touchLengthMoveTo:endTouch];
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
        panGesture.enabled = NO;
        
        isPinching = YES;
        pinchTouch0 = [recoginzer locationOfTouch:0 inView:self.view];
        pinchTouch1 = [recoginzer locationOfTouch:1 inView:self.view];
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        isPinching = NO;
        
        if (self.paperStatus == PaperNormal) {
            if (scope < -100) {
                // 捏合
               // [self foldAnimated];
            }else if(scope > 100){
                // 展开
                //[self unfoldAnimated];
            }else{
                //[self resetViewsAnimated:CGPointMake(0, 0) time:0.3];
                // 还原
            }
        }else if(self.paperStatus == PaperUnfold){
            if (scope < - 100) {
                // 还原
                //[self resetViewsAnimated:CGPointMake(0, 0) time:0.3];
            }else{
                // 展开
                //[self unfoldAnimated];
            }
        }else if(self.paperStatus == PaperFold){
            if (scope > 100 && scope < pinchSensitivity) {
                // 还原
                //[self resetViewsAnimated:CGPointMake(0, 0) time:0.6];
            }else if(scope > pinchSensitivity){
                // 展开
                //[self unfoldAnimated];
            }else{
                // 捏合
                //[self foldAnimated];
            }
        }
        [panGesture performSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.3];
        return;
        // cancal panning 回弹
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        isPinching = NO;
        //[self resetViewsAnimated:startTouch time:0.3];
        panGesture.enabled = YES;
        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        // 限制为双指操作
        if ([recoginzer numberOfTouches] <= 1) {
            return;
        }
        if (isPinching) {
            scope = 0;
            CGPoint touch0 = [recoginzer locationOfTouch:0 inView:self.view];
            CGPoint touch1 = [recoginzer locationOfTouch:1 inView:self.view];
            
            scope = [self pinchLengthMoveTo:touch0 anotherPoint:touch1];
            
            [self pinchChange:scope];
        }
    }
}

#pragma mark -
#pragma mark Rotation
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self changeSize:self.view.frame.size];
    moveSensitivity = self.view.frame.size.width;
}

@end

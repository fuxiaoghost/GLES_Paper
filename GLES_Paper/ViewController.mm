//
//  ViewController.m
//  GLES_Paper
//
//  Created by Dawn on 13-10-21.
//  Copyright (c) 2013年 Dawn. All rights reserved.
//

#import "ViewController.h"
#import "Define.h"

#define PAPER_FRAMESPERSECOND     30                            // 刷新频率
#define PAPER_MIN_ANGLE           (M_PI_4/6)                    // 书页夹角/2
#define PAPER_MAX_ANGLE           (M_PI_4)                      // (展开书页夹角 - 书页夹角)/2
#define PAPER_Z_DISTANCE          (-3.0f)                       // 沿z轴距离
#define PAPER_Z_MIN_DISTANCE      1.0f                          // 最小z轴距离
#define PAPER_PERSPECTIVE_NEAR    1.0f                          // 透视场近端
#define PAPER_PERSPECTIVE_FAR     20.0f                         // 透视场远端
#define PAPER_PERSPECTIVE_FOVY    60.0f                         // 透视仰角
#define PAPER_X_DISTANCE          sinf(PAPER_MIN_ANGLE)         // 沿x轴距离
#define PAPER_RADIUS              (2 * PAPER_X_DISTANCE)        // 绕轴旋转半径
#define PAPER_VELOCITY            3000                          // 滑动速度的阈值，超过此速度则进行减速衰减
#define PAPER_THETA               (M_PI - 2 * PAPER_MAX_ANGLE)  // 翻页的角度
#define PAPER_PRECISION           0.00001                      // 纠偏精度，防止float to int时出现偏差
#define PAPER_PAGENUM             5                             // 裁剪边界值，没一边的书页超过次数进行裁剪处理

@interface ViewController () {

}
@property (nonatomic, retain) NSArray *imagePathArray;           // 图片地址
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) PaperStatus paperStatus;           // 书页的当前状态(PaperNormal,PaperUnfold,PaperFold)
- (void)setupGL;
- (void)tearDownGL;
@end

@implementation ViewController

#pragma mark -
#pragma mark 内存管理

- (void)dealloc{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    self.context = nil;
    self.imagePathArray = nil;
    [paningAnimation release];
    
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

- (void)tearDownGL{
    // clear gl 
    [EAGLContext setCurrentContext:self.context];
    
    // delete shaders
    glDeleteProgram(paperFlatLightShader.shaderId);
    glDeleteProgram(backgroundFlatLightShader.shaderId);
    glDeleteProgram(paperShadowShader.shaderId);
    
    // delete textures
    glDeleteTextures(1, &paperTexture);
    glDeleteTextures(1, &shadowTexture);
    if (paperTextures != NULL) {
        for (int i = 0; i < imageCount; i++) {
            if (paperTextures[i] != 0) {
                glDeleteTextures(1, &paperTextures[i]);
            }
        }
    }
    
    // delete batchs
    if (paperBatchs != NULL) {
        delete [] paperBatchs;
        paperBatchs = NULL;
    }
    if (paperTextures != NULL) {
        delete [] paperTextures;
        paperTextures = NULL;
    }
}

#pragma mark -
#pragma mark 数据初始化

- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();
    [self initShaders];
    
    /* 准备纹理 */
    // 图片纹理
    [self loadTextureWithId:&paperTexture imageFilePath:[[NSBundle mainBundle] pathForResource:@"sex" ofType:@"png"]];
    [self loadTextureWithId:&shadowTexture imageFilePath:[[NSBundle mainBundle] pathForResource:@"shadow" ofType:@"png"]];
    [self createPapaerTextures];
    
    // 准备渲染图形的批次
    [self createPaperBatchArray];       // papers
    [self createBackgroundBatch];
}



- (id) initWithImagePaths:(NSArray *)paths{
    if (self = [super init]) {
        self.imagePathArray = [NSArray arrayWithArray:paths];
        imageCount = paths.count;
        paningAnimation = [[PaperAnimation alloc] init];
    }
    return self;
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
    
    // GL渲染容器层
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    
    
    // 设置Size
    if (([[UIApplication sharedApplication]statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication]statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
        CGSize size = CGSizeMake(SCREEN_HEIGHT,SCREEN_WIDTH);
        [self changeSize:size];
    }else{
        CGSize size = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
        
        [self changeSize:size];
    }
    
    // GL初始化配置
    [self setupGL];
    
    // 添加手势
    [self addGesture];
}

-(void) changeSize:(CGSize)size{
    frameSize = CGSizeMake(size.width, size.height);
    // 准备数据
    paningMove.moveSensitivity = frameSize.width/3;
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

- (void) addGesture{
    // 滑动翻页手势
    panGesture = [[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(paningGestureReceive:)]autorelease];
    [self.view addGestureRecognizer:panGesture];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    
    
    // 双指捏合手势
    pinchGesture = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureReceive:)] autorelease];
    [self.view addGestureRecognizer:pinchGesture];
//    [pinchGesture requireGestureRecognizerToFail:panGesture];
    
    // 点击手势
    UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureReceive:)] autorelease];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
//    [tapGesture requireGestureRecognizerToFail:panGesture];
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
    paperBatchs = new GLBatch[imageCount * 2];
    float z = 1.0f;
    for (int i = 0; i < imageCount * 2; i++) {
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

- (void) createPapaerTextures{
    paperTextures = new GLuint[imageCount];
    // 初始化
    for (int i = 0; i < imageCount; i++) {
        paperTextures[i] = 0;
    }
}

- (int) requestPaperTextureAtIndex:(NSInteger)index{    
    NSInteger bufferCount = MIN(imageCount, PAPER_PAGENUM * 2);
   
    if (paperTextures[index] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadTextureWithId:&paperTextures[index] imageFilePath:[self.imagePathArray objectAtIndex:index]];
        });
        
        for (int i = 0; i < imageCount; i++) {
            if (i < self.pageIndex - bufferCount/2 || i > bufferCount/2 + self.pageIndex) {
                if (paperTextures[i] != 0) {
                    glDeleteTextures(1, &paperTextures[i]);
                    paperTextures[i] = 0;
                }
            }
        }
        return paperTexture;
    }else{
        return paperTextures[index];
    }
}

#pragma mark -
#pragma mark 构造需要的着色器

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
    backgroundFlatLightShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp,3,GLT_ATTRIBUTE_VERTEX,"vVertex",GLT_ATTRIBUTE_NORMAL,"vNormal");
    backgroundFlatLightShader.mvpMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvpMatrix");
    backgroundFlatLightShader.mvMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvMatrix");
    backgroundFlatLightShader.mvsMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "mvsMatrix");
    backgroundFlatLightShader.normalMatrix = glGetUniformLocation(backgroundFlatLightShader.shaderId, "normalMatrix");
    backgroundFlatLightShader.lightPosition = glGetUniformLocation(backgroundFlatLightShader.shaderId, "lightPosition");
    backgroundFlatLightShader.lightColor = glGetUniformLocation(backgroundFlatLightShader.shaderId, "lightColor");
    backgroundFlatLightShader.shadowMap = glGetUniformLocation(backgroundFlatLightShader.shaderId, "shadowMap");
    
    // papershadow shader
    vp = [[[NSBundle mainBundle] pathForResource:@"PaperShadow" ofType:@"vsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    fp = [[[NSBundle mainBundle] pathForResource:@"PaperShadow" ofType:@"fsh"] cStringUsingEncoding:NSUTF8StringEncoding];
    paperShadowShader.shaderId = shaderManager.LoadShaderPairWithAttributes(vp, fp,3,GLT_ATTRIBUTE_VERTEX,"vVertex",GLT_ATTRIBUTE_TEXTURE0,"vTexCoord");
    paperShadowShader.mvpMatrix = glGetUniformLocation(paperShadowShader.shaderId, "mvpMatrix");
    paperShadowShader.mvMatrix = glGetUniformLocation(paperShadowShader.shaderId, "mvMatrix");
    paperShadowShader.colorMap = glGetUniformLocation(paperShadowShader.shaderId, "colorMap");
}


#pragma mark - 
#pragma mark 绘图
// 绘制所有的书页
- (void) drawPapersLookAt:(M3DMatrix44f)lookAt shadow:(BOOL)shadow{
    self.pageIndex = ((int)((paningMove.theta + PAPER_PRECISION)/ PAPER_THETA));
    
    // 
    float theta = ABS(paningMove.theta - PAPER_THETA * self.pageIndex);
    if (theta > PAPER_THETA) {
        theta = theta - PAPER_THETA;
    }
    
    float y = PAPER_RADIUS * sinf(theta)/sinf(M_PI - 2 * PAPER_MAX_ANGLE);
    float alpha = M_PI - 2 * PAPER_MAX_ANGLE;
    float x = 0.5 * (-(2 * y * cosf(alpha) - 2 * PAPER_RADIUS) - sqrtf((2 * y * cosf(alpha) - 2 * PAPER_RADIUS) * (2 * y * cosf(alpha) - 2 * PAPER_RADIUS) - 4 * (y * y - 2 * PAPER_RADIUS * y * cosf(alpha))));
    if (isnan(x)) {
        x = y;
    }
    
    // 奇数旋转-PAPER_MIN_ANGLE；偶数旋转PAPER_MIN_ANGLE
    for (int i = 0; i < imageCount * 2 ; i++) {
        NSInteger index = (i % 2 == 0 ? i/2 : (i + 1)/2);
        
        // 裁剪多余书页
        if (index - self.pageIndex < 0) {
            if (self.pageIndex - index >= PAPER_PAGENUM) {
                continue;
            }
        }else{
            if (index - self.pageIndex >= PAPER_PAGENUM + 2) {
                continue;
            }
        }
        
        
        // 4、照相机机位
        paperPipeline.modelViewMatrix.PushMatrix(lookAt);
        if (pinchMove.scope < 0) {
            paperPipeline.modelViewMatrix.Translate(0, 0, PAPER_Z_DISTANCE + PAPER_Z_MIN_DISTANCE * pinchMove.scope);
        }else{
            paperPipeline.modelViewMatrix.Translate(0, 0, PAPER_Z_DISTANCE + (abs(PAPER_Z_DISTANCE) - tanf(m3dDegToRad(PAPER_PERSPECTIVE_FOVY))) * pinchMove.scope);
        }
        
        
        // 3、绕y轴旋转
        float yRotate = 0;
        if (index <= self.pageIndex) {
            if (pinchMove.scope < 0) {
                yRotate = -PAPER_MAX_ANGLE - pinchMove.scope * PAPER_MAX_ANGLE;
            }else{
                yRotate = -PAPER_MAX_ANGLE + (PAPER_MIN_ANGLE - PAPER_MAX_ANGLE) * pinchMove.scope;
            }
        }else{
            if (pinchMove.scope < 0) {
                yRotate = PAPER_MAX_ANGLE + pinchMove.scope * PAPER_MAX_ANGLE;
            }else{
                yRotate = PAPER_MAX_ANGLE - (PAPER_MIN_ANGLE - PAPER_MAX_ANGLE) * pinchMove.scope;
            }
        }
        paperPipeline.modelViewMatrix.Rotate(yRotate, 0, 1, 0);
        
        // 2、绕固定点旋转
        if (index == self.pageIndex + 1) {
            // 2.2
            paperPipeline.modelViewMatrix.Translate(PAPER_RADIUS - x, 0, 0);
            // 2.1
            paperPipeline.modelViewMatrix.Rotate(-theta, 0, 1, 0);
            // 2.0
            paperPipeline.modelViewMatrix.Translate(-(PAPER_RADIUS - x), 0, 0);;
        }
        
        // 1、整体沿+x移动 PAPER_X_DISTANCE
        float xDistance = 0;
        if (pinchMove.scope < 0) {
            xDistance = (i/2 - self.pageIndex) * 2 * sinf(PAPER_MIN_ANGLE + PAPER_MIN_ANGLE * pinchMove.scope);
        }else{
            xDistance = (i/2 - self.pageIndex) * 2 * sinf(PAPER_MIN_ANGLE);
        }
        float xOffset = (index - self.pageIndex) <= 0 ? -y : -x;
        
        // 隐藏多余的书页
        float zOffset = 0.0f;
        if (index - self.pageIndex < 0) {
            if (self.pageIndex - index >= PAPER_PAGENUM-1) {
                zOffset = -theta * 0.08;
            }
        }else{
            if (index - self.pageIndex >= PAPER_PAGENUM+1) {
                zOffset = -(PAPER_THETA - theta) * 0.08;
            }
        }

        paperPipeline.modelViewMatrix.Translate(xDistance + xOffset, 0, zOffset);
        
        // 0、自身旋转
        if (i % 2 != 0) {
            if (pinchMove.scope < 0) {
                paperPipeline.modelViewMatrix.Rotate(PAPER_MIN_ANGLE + PAPER_MIN_ANGLE * pinchMove.scope, 0, 1, 0);
            }else{
                paperPipeline.modelViewMatrix.Rotate(PAPER_MIN_ANGLE, 0, 1, 0);
            }
        }else{
            if (pinchMove.scope < 0) {
                paperPipeline.modelViewMatrix.Rotate(-PAPER_MIN_ANGLE - PAPER_MIN_ANGLE * pinchMove.scope, 0, 1, 0);
            }else{
                paperPipeline.modelViewMatrix.Rotate(-PAPER_MIN_ANGLE, 0, 1, 0);
            }
        }
        
        if (shadow) {
            
            // 启用书页光照着色器
            glUseProgram(paperShadowShader.shaderId);
            glUniformMatrix4fv(paperShadowShader.mvpMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetModelViewProjectionMatrix());
            glUniformMatrix4fv(paperShadowShader.mvMatrix, 1, GL_FALSE, paperPipeline.transformPipeline.GetModelViewMatrix());
        
            glUniform1f(paperShadowShader.colorMap, 0);
            
            // 纹理
            glBindTexture(GL_TEXTURE_2D, shadowTexture);
            
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
            if (i == 0 || i == imageCount * 2 - 1) {
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
            NSInteger tindex = (i % 2 == 0 ? i/2 : (i - 1)/2);
            glBindTexture(GL_TEXTURE_2D, [self requestPaperTextureAtIndex:tindex]);
            
            paperBatchs[i].Draw();
        }
        
        paperPipeline.modelViewMatrix.PopMatrix();
    }
}
- (void) drawPapers{
    M3DMatrix44f lookAt;
    m3dLoadIdentity44(lookAt);
    [self drawPapersLookAt:lookAt shadow:NO];
}

// 绘制书页投影
- (void) drawShadows{
   // create the projection matrix from the cameras view
    static const GLKVector3 kLightPosition = {0.0, 0.0, 0.0 };      // 观察点
    static const GLKVector3 kLightLookAt = { 0, 0.04, -1.0 };       // 中心点
    GLKMatrix4 cameraViewMatrix = GLKMatrix4MakeLookAt(kLightPosition.x, kLightPosition.y, kLightPosition.z, kLightLookAt.x, kLightLookAt.y, kLightLookAt.z, 0, 1, 0);
    
    [self drawPapersLookAt:cameraViewMatrix.m shadow:YES];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 
    [paningAnimation animationTimerStep:1.0/self.framesPerSecond];
    
    // 清理画布
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    // 清除颜色缓冲区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 启用颜色抖动
    glEnable(GL_DITHER);
    
    /************************准备开整**************************/
    
    // 深度只读
    glDepthMask(GL_FALSE);
    
    // 启用混合
    glEnable(GL_BLEND);
    glBlendFunc( GL_SRC_ALPHA , GL_ONE_MINUS_SRC_ALPHA );
    
    // 在缓冲区绘制阴影
    //[self drawShadows];
    glDisable(GL_BLEND);
    
    // 深度读写
    glDepthMask(GL_TRUE);
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    
    // 绘制书页
    [self drawPapers];
}


#pragma mark -
#pragma mark PanMove & PinchMove

- (float) pinchLengthMoveTo:(CGPoint)touchPoint0 anotherPoint:(CGPoint)touchPoint1{
    float x0 = ABS(pinchMove.pinchTouch0.x - pinchMove.pinchTouch1.x);
    float x1 =  ABS(touchPoint0.x - touchPoint1.x);
    return x1 - x0;
}

#pragma mark -
#pragma mark GestureReceive
// 点击
- (void) tapGestureReceive:(UITapGestureRecognizer *)recoginzer{
    if (self.paperStatus == PaperUnfold) {
        [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:0.0f];
        self.paperStatus = PaperNormal;
    }else if(self.paperStatus == PaperNormal){
        [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:1.0f];
        self.paperStatus = PaperUnfold;
    }
}

// 滑动
- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer{
    if (self.paperStatus == PaperUnfold) {
        return;
    }
    
    if (pinchMove.isPinching) {
        return;
    }

    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        paningMove.isMoving = YES;                  // 标记状态开始滑动
        paningMove.move = 0.0f;                     // 重置滑动距离
        paningMove.startTheta = paningMove.theta;   // 记录翻页旋转角度
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        [self performSelector:@selector(paningEnd:) withObject:[NSNumber numberWithFloat:-[recoginzer velocityInView:self.view].x] afterDelay:0.1];
        return;
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        if (paningMove.isMoving) {
            // 手指滑动过程中通过插值算法填充间断点
            float move = -[recoginzer translationInView:self.view].x;
            paningMove.move = move;
            float theta = [self changeMoveToTheta:move]; // 距离换算， 把滑动距离换算为书页的实际旋转角度
            float toValue = theta + paningMove.startTheta;
            
            // 限定两个极限点
            if (toValue < 0.0f) {
                toValue = 0.0f;
            }
            if (toValue > PAPER_THETA * (imageCount - 1)) {
                toValue = PAPER_THETA * (imageCount - 1);
            }
            [paningAnimation animateEasyOutWithDuration:0.3 valueFrom:&paningMove.theta valueTo:toValue];
        }
    }
}

- (float) changeMoveToTheta:(float)move{
    float index = (int)(move/paningMove.moveSensitivity);
    float theta = index * PAPER_THETA + PAPER_THETA * (move - index * paningMove.moveSensitivity)/paningMove.moveSensitivity;
    return theta;
}

- (void) paningEnd:(id)obj{
    float velocity = [obj floatValue];
    
    float x = velocity;
    // 速度大于阈值进行衰减处理
    if (ABS(x) > PAPER_VELOCITY) {
        NSLog(@"%f",ABS(x));
        
        float toValue = x * 0.3/2;      // 衰减距离
        
        float toThetaValue = PAPER_THETA * toValue/paningMove.moveSensitivity;
        int count = (int)((toThetaValue + paningMove.theta + PAPER_PRECISION)/PAPER_THETA);
        float theta = count * PAPER_THETA;
        
        float min = 0;
        float max = PAPER_THETA * (imageCount - 1);
        float xto = theta;
        
        // 限定两个极限点
        if (xto > max) {
            xto = max;
        }else if(xto < min){
            xto = min;
        }
        [paningAnimation animateEasyOutWithDuration:0.6 valueFrom:&paningMove.theta valueTo:xto];
    }else{
        int index = (int)((paningMove.theta + PAPER_PRECISION)/PAPER_THETA);
        
        // 控制两个极限点
        if (paningMove.theta < 0) {
            index = 0;
        }
        if (index > imageCount - 1) {
            index = imageCount - 1;
        }
        
        // 左右翻页的监测点
        float leave = paningMove.theta - index * PAPER_THETA;
        if (paningMove.move < 0) {
            leave = PAPER_THETA - leave;
        }
        
        // 如果加速度大于PAPER_VELOCITY/2 或者 超过PAPER_THETA * 0.1 翻页，否则归位
        if ((ABS(x)>PAPER_VELOCITY/4)||(leave > PAPER_THETA * 0.1)) {
            if (paningMove.move > 0) {
                index = index + 1;
                if (index > imageCount - 1) {
                    index = imageCount - 1;
                }
            }
            [paningAnimation animateEasyOutWithDuration:0.3 valueFrom:&paningMove.theta valueTo:PAPER_THETA * index];
        }else{
            if (paningMove.move < 0) {
                index = index + 1;
                if (index > imageCount - 1) {
                    index = imageCount - 1;
                }
            }
            [paningAnimation animateEasyOutWithDuration:0.3 valueFrom:&paningMove.theta valueTo:PAPER_THETA * index];
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
        pinchMove.startScope = pinchMove.scope;
        pinchMove.isPinching = YES;
        pinchMove.pinchTouch0 = [recoginzer locationOfTouch:0 inView:self.view];
        pinchMove.pinchTouch1 = [recoginzer locationOfTouch:1 inView:self.view];
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        pinchMove.isPinching = NO;
        [self performSelector:@selector(pinchEnd) withObject:nil afterDelay:0.2];
        return;
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        return;
    }else if(recoginzer.state == UIGestureRecognizerStateChanged){
        // 限制为双指操作
        if ([recoginzer numberOfTouches] <= 1) {
            return;
        }
        if (pinchMove.isPinching) {
            
            CGPoint touch0 = [recoginzer locationOfTouch:0 inView:self.view];
            CGPoint touch1 = [recoginzer locationOfTouch:1 inView:self.view];
            float toValue = pinchMove.startScope + [self pinchLengthMoveTo:touch0 anotherPoint:touch1]/pinchMove.pinchSensitivity;
            if (toValue < -1.0 + 0.1f) {
                toValue = -1.0f + 0.1f;
            }
            if (toValue > 1.0f) {
                toValue = 1.0f;
            }
            [paningAnimation animateEasyOutWithDuration:0.2 valueFrom:&pinchMove.scope valueTo:toValue];
        }
    }
}

- (void) pinchEnd{
    if (self.paperStatus == PaperNormal) {
        if(pinchMove.scope > 0.1f){
            // 展开
            [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:1.0f];
            self.paperStatus = PaperUnfold;
        }else{
            // 还原
            [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:0.0f];
        }
    }else if(self.paperStatus == PaperUnfold){
        if (pinchMove.scope < 1.0f - 0.1f) {
            // 还原
            [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:0.0f];
            self.paperStatus = PaperNormal;
        }else{
            // 展开
            [paningAnimation animateEasyOutWithDuration:0.4 valueFrom:&pinchMove.scope valueTo:1.0f];
        }
    }
}


#pragma mark -
#pragma mark Rotation

- (BOOL) shouldAutorotate{
    return YES;
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

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

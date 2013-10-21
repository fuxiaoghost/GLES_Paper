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

@interface ViewController : GLKViewController{
@private
    GLShaderManager shaderManager;
    GLBatch redBatch;
}

@end

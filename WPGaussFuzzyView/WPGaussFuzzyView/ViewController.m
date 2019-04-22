//
//  ViewController.m
//  WPGaussFuzzyView
//
//  Created by 李伟鹏的MacBook on 2019/4/22.
//  Copyright © 2019 李伟鹏的MacBook. All rights reserved.
//

#import "ViewController.h"
#import <Accelerate/Accelerate.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
}


//高斯模糊
-(UIImage *)getBlurBackgroundImage: (UIImage *)image
{
    NSData *imageAsData = UIImageJPEGRepresentation(image, 0.1);
    UIImage *downsampledImaged = [UIImage imageWithData:imageAsData];
    UIImage *blurImage = [self blurryImage:downsampledImaged withBlurLevel:0.8f];
    return  blurImage;
}

- (UIImage*)downSizeOriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
    if (!image) {
        return nil;
    }
    //预处理图片保证不同尺寸虚化效果相同
    if (image.size.width > 420 || image.size.height > 420) {
        image = [self downSizeOriginImage:image scaleToSize:CGSizeMake(420, 420)];
    }else if (image.size.width < 200 || image.size.height < 200) {
        blur = blur * 0.3;
    }
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [image scale]);
    CGContextRef effectInContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(effectInContext, 1.0, -1.0);
    CGContextTranslateCTM(effectInContext, 0, -image.size.height);
    CGContextDrawImage(effectInContext, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    vImage_Buffer effectInBuffer;
    effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
    effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
    effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
    effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [image scale]);
    CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
    vImage_Buffer effectOutBuffer;
    effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
    effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
    effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
    effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
    
    BOOL hasBlur = blur > __FLT_EPSILON__;
    
    if (hasBlur) {
        CGFloat inputRadius = blur * [[UIScreen mainScreen] scale];
        unsigned int radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
        if (radius % 2 != 1) {
            radius += 1; // force radius to be odd so that the three box-blur methodology works.
        }
        vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
    }
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}


@end

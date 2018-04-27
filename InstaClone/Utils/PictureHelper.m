
#import "PictureHelper.h"
#import "PostCell.h"
#import "LikeCell.h"

#define IMAGES_KEY @"instaCloneImages"

@implementation PictureHelper

+ (instancetype)sharedInstance {
    static PictureHelper *sharedHelper;
    @synchronized(self) {
        if (!sharedHelper)
            sharedHelper = [PictureHelper new];
    }
    return sharedHelper;
}

- (void)setProfilePicture:(NSString *)profilePicture forCell:(UITableViewCell *)cell {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image;
            if ([self getImageFromUserDefaults:profilePicture]) {
                image = [self getImageFromUserDefaults:profilePicture];
            }
            else {
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:profilePicture]]];
                [self saveImageToUserDefaults:image withKey:profilePicture];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([cell isKindOfClass:[PostCell class]]) {
                    ((PostCell *)cell).profileImageView.image = image;
                }
                else if ([cell isKindOfClass:[LikeCell class]]) {
                    ((LikeCell *)cell).profileImageView.image = image;
                }                
            });
        });
}

- (void)setPostPhoto:(NSString *)photo forCell:(UITableViewCell *)cell {
    if ([cell isKindOfClass:[PostCell class]]) {
        PostCell *postCell = (PostCell *)cell;
        if (!postCell.postImageView.image) {
            postCell.activityIndicator.hidden = NO;
            [postCell.activityIndicator startAnimating];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image;
            if ([self getImageFromUserDefaults:photo]) {
                image = [self getImageFromUserDefaults:photo];
            }
            else {
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo]]];
                [self saveImageToUserDefaults:image withKey:photo];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                postCell.postImageView.image = image;
                postCell.activityIndicator.hidden = YES;
                [postCell.activityIndicator stopAnimating];
            });
        });
    }
}

-(UIImage *)scaleAndRotateImage:(UIImage *)image {
    image = [self scaleImage:image];
    image = [self rotateImage:image];
    return image;
}

- (UIImage *)scaleImage:(UIImage *)image {
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat maxSize = 1080;
    
    if (imageWidth > maxSize && imageHeight > maxSize) {
        if (imageWidth >= imageHeight) {
            CGFloat coef = imageWidth / maxSize;
            imageWidth = maxSize;
            imageHeight = imageHeight / coef;
        }
        else {
            CGFloat coef = imageHeight / maxSize;
            imageHeight = maxSize;
            imageWidth = imageWidth / coef;
        }
    }
    
    CGSize newSize = CGSizeMake(imageWidth, imageHeight);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)rotateImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

-(void)saveImageToUserDefaults:(UIImage *)image withKey:(NSString *)key {
    if (image) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:IMAGES_KEY];
        NSMutableDictionary *images = [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
        if (!images) {
            images = [NSMutableDictionary new];
        }
        if (![images objectForKey:key]) {
            [images setObject:image forKey:key];
            data = [NSKeyedArchiver archivedDataWithRootObject:images];
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:IMAGES_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(UIImage *)getImageFromUserDefaults:(NSString *)key {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:IMAGES_KEY];
    NSMutableDictionary *images = [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    if (images) {
        return [images valueForKey:key];
    }
    return nil;
}

@end
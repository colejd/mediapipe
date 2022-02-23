#import "HandTracker.h"

// I've had a lot of trouble getting this framework to work on the iOS Simulator because
// of MediaPipe. So for that arch, we're not linking to MediaPipe, and we're providing a
// "null" implementation of HandTracker.h, which doesn't reference MediaPipe at all.

@interface Landmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@implementation HandTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
}

#pragma mark - MediaPipe graph methods

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)startGraph {
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
    // Just republish the frame immediately
    [_delegate handTracker: self didOutputPixelBuffer: imageBuffer];
}

@end


@implementation Landmark

- (instancetype)initWithX:(float)x y:(float)y z:(float)z
{
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}

@end

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class Landmark;
@class HandTracker;

@protocol TrackerDelegate <NSObject>
- (void)handTracker: (HandTracker*)handTracker didOutputHandLandmarks: (NSArray<NSArray<Landmark *> *> *)hands;
- (void)handTracker: (HandTracker*)handTracker didOutputHandWorldLandmarks: (NSArray<NSArray<Landmark *> *> *)hands;
- (void)handTracker: (HandTracker*)handTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface HandTracker : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@property(nonatomic) BOOL debugLoggingEnabled;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end

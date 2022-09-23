#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class Landmark;
@class HandTracker;
@class NormalizedRect;

@protocol TrackerDelegate <NSObject>
- (void)handTracker: (HandTracker*)handTracker didOutputHandLandmarks: (NSArray<NSArray<Landmark *> *> *)hands;
- (void)handTracker: (HandTracker*)handTracker didOutputHandWorldLandmarks: (NSArray<NSArray<Landmark *> *> *)hands;
- (void)handTracker: (HandTracker*)handTracker didOutputNormalizedPalmRects: (NSArray<NormalizedRect *> *)rects;
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

/// A rectangle with rotation in normalized coordinates. The values of box center
/// location and size are within [0, 1].
/// This is an objc type meant to wrap `mediapipe/framework/formats/rect.proto`.
@interface NormalizedRect: NSObject
@property(nonatomic, readonly) float xCenter;
@property(nonatomic, readonly) float yCenter;
@property(nonatomic, readonly) float width;
@property(nonatomic, readonly) float height;
// /// Rotation angle is clockwise in radians.
// @property(nonatomic, readonly) float rotation;
// /// Optional unique id to help associate different NormalizedRects to each other.
// @property(nonatomic, readonly) int rectId;
@end
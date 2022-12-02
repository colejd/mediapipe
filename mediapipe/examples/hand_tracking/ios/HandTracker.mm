#import "HandTracker.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"

static NSString* const kGraphName = @"hand_tracking_mobile_gpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";
static const char* kLandmarksOutputStream = "hand_landmarks";
static const char* kWorldLandmarksOutputStream = "hand_world_landmarks";
static const char* kNumHandsInputSidePacket = "num_hands";
static const char* kHandRectsFromPalmDetections = "hand_rects_from_palm_detections";

// // Max number of hands to detect/process.
// static const int kNumHands = 2;

@interface HandTracker() <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@end

@interface Landmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@interface NormalizedRect()
- (instancetype)initWithXCenter:(float)xCenter yCenter:(float)yCenter width:(float)width height:(float)height;
@end

@implementation HandTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource numHands:(int)numHands {
    // Load the graph config resource.
    NSError* configLoadError = nil;
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }
    
    // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, data.length);
    
    // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
    MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    [newGraph setSidePacket:(mediapipe::MakePacket<int>(numHands))
                               named:kNumHandsInputSidePacket];
    [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
    [newGraph addFrameOutputStream:kLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kWorldLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kHandRectsFromPalmDetections outputPacketType:MPPPacketTypeRaw];
    return newGraph;
}

- (instancetype)init:(int)kNumHands
{
    self = [super init];
    if (self) {    
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName numHands:kNumHands];
        self.mediapipeGraph.delegate = self;
        // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
        self.mediapipeGraph.maxFramesInFlight = 2;
        self.kNumHands = kNumHands;
    }
    return self;
}

- (void)startGraph {
    // Start running self.mediapipeGraph.
    NSError* error;
    if (![self.mediapipeGraph startWithError:&error]) {
        NSLog(@"Failed to start graph: %@", error);
    }
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
      if (streamName == kOutputStream) {
          [_delegate handTracker: self didOutputPixelBuffer: pixelBuffer];
      }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
    if (streamName == kLandmarksOutputStream) {
        if (packet.IsEmpty()) {
            if (_debugLoggingEnabled) {
                NSLog(@"[TS:%lld] No hand landmarks", packet.Timestamp().Value());
            }
            return; 
        }

        const auto& multiHandLandmarks = packet.Get<std::vector<::mediapipe::NormalizedLandmarkList>>();
        if (_debugLoggingEnabled) {
            NSLog(@"[TS:%lld] Number of hand instances with landmarks: %lu", packet.Timestamp().Value(),
            multiHandLandmarks.size());
        }
        // const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
        
        //        for (int i = 0; i < landmarks.landmark_size(); ++i) {
        //            NSLog(@"\tLandmark[%d]: (%f, %f, %f)", i, landmarks.landmark(i).x(),
        //                  landmarks.landmark(i).y(), landmarks.landmark(i).z());
        //        }
        // NSMutableArray<Landmark *> *result = [NSMutableArray array];
        // for (int i = 0; i < landmarks.landmark_size(); ++i) {
        //     Landmark *landmark = [[Landmark alloc] initWithX:landmarks.landmark(i).x()
        //                                                    y:landmarks.landmark(i).y()
        //                                                    z:landmarks.landmark(i).z()];
        //     [result addObject:landmark];
        // }
        // [_delegate handTracker: self didOutputLandmarks: result];

        NSMutableArray<NSMutableArray<Landmark *> *> *result = [NSMutableArray array];
        for (int handIndex = 0; handIndex < multiHandLandmarks.size(); ++handIndex) {
            NSMutableArray<Landmark *> *arr = [NSMutableArray array];
            const auto& landmarks = multiHandLandmarks[handIndex];
            if (_debugLoggingEnabled) {
                NSLog(@"\tNumber of landmarks for hand[%d]: %d", handIndex, landmarks.landmark_size());
            }
            for (int i = 0; i < landmarks.landmark_size(); ++i) {
                if (_debugLoggingEnabled) {
                    NSLog(@"\t\tLandmark[%d]: (%f, %f, %f)", i, landmarks.landmark(i).x(),
                        landmarks.landmark(i).y(), landmarks.landmark(i).z());
                }
                Landmark *landmark = [[Landmark alloc] initWithX:landmarks.landmark(i).x()
                                                           y:landmarks.landmark(i).y()
                                                           z:landmarks.landmark(i).z()];
                [arr addObject:landmark];
            }
            [result addObject:arr];
        }
        [_delegate handTracker: self didOutputHandLandmarks: result];
    }

    if (streamName == kWorldLandmarksOutputStream) {
        if (packet.IsEmpty()) {
            if (_debugLoggingEnabled) {
                NSLog(@"[TS:%lld] No world hand landmarks", packet.Timestamp().Value());
            }
            return; 
        }

        const auto& multiHandLandmarks = packet.Get<std::vector<::mediapipe::LandmarkList>>();
        if (_debugLoggingEnabled) {
            NSLog(@"[TS:%lld] Number of world hand instances with landmarks: %lu", packet.Timestamp().Value(),
                multiHandLandmarks.size());
        }

        NSMutableArray<NSMutableArray<Landmark *> *> *result = [NSMutableArray array];
        for (int handIndex = 0; handIndex < multiHandLandmarks.size(); ++handIndex) {
            NSMutableArray<Landmark *> *arr = [NSMutableArray array];
            const auto& landmarks = multiHandLandmarks[handIndex];
            if (_debugLoggingEnabled) {
                NSLog(@"\tNumber of world landmarks for hand[%d]: %d", handIndex, landmarks.landmark_size());
            }
            for (int i = 0; i < landmarks.landmark_size(); ++i) {
                if (_debugLoggingEnabled) {
                    NSLog(@"\t\tWorld Landmark[%d]: (%f, %f, %f)", i, landmarks.landmark(i).x(),
                        landmarks.landmark(i).y(), landmarks.landmark(i).z());
                }
                Landmark *landmark = [[Landmark alloc] initWithX:landmarks.landmark(i).x()
                                                           y:landmarks.landmark(i).y()
                                                           z:landmarks.landmark(i).z()];
                [arr addObject:landmark];
            }
            [result addObject:arr];
        }
        [_delegate handTracker: self didOutputHandWorldLandmarks: result];
    }

    if (streamName == kHandRectsFromPalmDetections) {
        const auto& rects = packet.Get<std::vector<::mediapipe::NormalizedRect>>();
        NSMutableArray<NormalizedRect *> *arr = [NSMutableArray array];
        if (_debugLoggingEnabled) {
            NSLog(@"\tNumber of palm rects: %lu", rects.size());
        }
        for (int i = 0; i < rects.size(); ++i) {
            NormalizedRect *rect = [[NormalizedRect alloc] initWithXCenter:rects[i].x_center()
                                                           yCenter:rects[i].y_center()
                                                           width:rects[i].width()
                                                           height:rects[i].height()
                                                           ];
            [arr addObject:rect];
        }
        [_delegate handTracker: self didOutputNormalizedPalmRects: arr];
    }
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
    [self.mediapipeGraph sendPixelBuffer:imageBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypePixelBuffer];
}

- (void)setNumHands:(int)numHands {
    self.kNumHands = numHands;

    // Repeat everything from deinit

    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
    // TODO: We crash here when this is called. waitUntilDoneWithError must be called
    // from a background thread because it never times out (!!!!!!!)
    // See here: https://github.com/google/mediapipe/blob/ead41132a856379a9a7d22f29abe471dc11f2b4a/mediapipe/objc/MPPGraph.h#L234
    // It might be that it's better to change kNumHands by just reinitializing the whole HandTracker object externally.

    // Repeat everything from init

    self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName numHands:numHands];
    self.mediapipeGraph.delegate = self;
    // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
    self.mediapipeGraph.maxFramesInFlight = 2;

    [self startGraph];
}

- (int)getNumHands {
    return self.kNumHands;
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

@implementation NormalizedRect

- (instancetype)initWithXCenter:(float)xCenter yCenter:(float)yCenter width:(float)width height:(float)height
{
    self = [super init];
    if (self) {
        _xCenter = xCenter;
        _yCenter = yCenter;
        _width = width;
        _height = height;
    }
    return self;
}

@end

# https://github.com/bazelbuild/rules_apple/tree/master/doc
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
# load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library") 

ios_framework(
    name = "HandTracker",
    hdrs = [
        "HandTracker.h",
    ],
    infoplists = ["Info.plist"],
    bundle_id = "com.proofofconcept.HandTracker",
    families = ["iphone", "ipad"],
    minimum_os_version = "11.1",
    deps = select({
        "//mediapipe:ios_sim_arm64": [
            ":HandTrackerLibrary",
        ],
        "//conditions:default": [
            ":HandTrackerLibrary",
            "@ios_opencv//:OpencvFramework",
        ],
    }),
)

objc_library(
    name = "HandTrackerLibrary",
    srcs = select({
        "//mediapipe:ios_sim_arm64": [
            "HandTrackerNull.mm",
        ],
        "//conditions:default": [
            "HandTracker.mm",
        ],
    }),
    hdrs = [
        "HandTracker.h",
    ],
    copts = ["-std=c++17"],
    data = select({
        "//mediapipe:ios_sim_arm64": [],
        "//conditions:default": [
            "//mediapipe/graphs/hand_tracking:hand_tracking_mobile_gpu.binarypb",
            "//mediapipe/modules/hand_landmark:hand_landmark_full.tflite",
            "//mediapipe/modules/hand_landmark:handedness.txt",
            "//mediapipe/modules/palm_detection:palm_detection_full.tflite",
        ],
    }),
    sdk_frameworks = [
        "AVFoundation",
        "CoreGraphics",
        "CoreMedia",
        "UIKit"
    ],
    deps = select({
        # https://github.com/google/mediapipe/issues/2132#issuecomment-926344776
        # "//mediapipe:ios_i386": [],
        # "//mediapipe:ios_x86_64": [],
        "//mediapipe:ios_sim_arm64": [],
        "//conditions:default": [
            "//mediapipe/objc:mediapipe_framework_ios",
            "//mediapipe/objc:mediapipe_input_sources_ios",
            "//mediapipe/objc:mediapipe_layer_renderer",
            "//mediapipe/graphs/hand_tracking:mobile_calculators",
            "//mediapipe/framework/formats:landmark_cc_proto",
        ],
    }),
)
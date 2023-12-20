# https://github.com/bazelbuild/rules_apple/tree/master/doc
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
# load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:apple.bzl", "apple_xcframework")

# ios_framework(name, additional_linker_inputs, bundle_id, bundle_name, bundle_only, codesign_inputs,
#               codesignopts, deps, executable_name, exported_symbols_lists, extension_safe, families,
#               frameworks, hdrs, infoplists, ipa_post_processor, linkopts,
#               minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile,
#               resources, stamp, strings, version)

# ios_framework(
#     name = "HandTracker",
#     hdrs = [
#         "HandTracker.h",
#     ],
#     infoplists = ["Info.plist"],
#     bundle_id = "com.proofofconcept.HandTracker",
#     families = ["iphone", "ipad"],
#     minimum_os_version = "11.1",
#     deps = select({
#         "//mediapipe:ios_sim_arm64": [
#             ":HandTrackerLibrary",
#         ],
#         "//conditions:default": [
#             ":HandTrackerLibrary",
#             "@ios_opencv//:OpencvFramework",
#         ],
#     }),
# )

# apple_xcframework(name, bundle_id, bundle_name, data, deps, exported_symbols_lists,
#                   families_required, framework_type, infoplists, ios, linkopts,
#                   minimum_deployment_os_versions, minimum_os_versions, public_hdrs, stamp, version)

apple_xcframework(
    name = "HandTracker",
    public_hdrs = [
        "HandTracker.h",
    ],
    infoplists = ["Info.plist"],
    bundle_id = "com.proofofconcept.HandTracker",
    ios = {
        "simulator": [
            "arm64",
            "x86_64",
        ],
        "device": [
            "x86_64",
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": "15.0",
    },
    deps = select({
        "//conditions:default": [
            ":HandTrackerLibrary",
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
            "@ios_opencv//:OpencvFramework",
            "//mediapipe/objc:mediapipe_framework_ios",
            "//mediapipe/objc:mediapipe_input_sources_ios",
            "//mediapipe/objc:mediapipe_layer_renderer",
            "//mediapipe/graphs/hand_tracking:mobile_calculators",
            "//mediapipe/calculators/core:packet_presence_calculator",
            "//mediapipe/framework/formats:landmark_cc_proto",
        ],
    }),
)
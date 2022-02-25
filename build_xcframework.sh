#!/bin/sh

# Cribbed from https://github.com/swittk/MediapipeFaceMeshIOSLibrary/blob/master/BUILD_FACE_MESH_XCFRAMEWORK.sh

rm ./buildlog-arm64.txt
rm ./buildlog-sim-arm64.txt
rm ./buildlog-x86_64.txt
rm -rf ./frameworkbuild

# Create output directories
mkdir -p ./frameworkbuild/HandTracker/arm64
mkdir -p ./frameworkbuild/HandTracker/arm64_sim
mkdir -p ./frameworkbuild/HandTracker/x86_64
# XCFramework is how we're going to use it.
mkdir -p ./frameworkbuild/HandTracker/xcframework

# Interesting fact. Bazel `build` command stores cached files in `/private/var/tmp/...` folders
# and when you run build, if it finds cached files, it kind of symlinks the files/folders
# into the `bazel-bin` folder found in the project root. So don't be afraid of re-running builds
# because the files are cached.

# =======================================
# build the arm64 binary framework

echo ""
echo "=================================="
echo "BUILDING ios_arm64 FRAMEWORK"
echo "=================================="

set -o pipefail
bazel build --color=yes --copt=-fembed-bitcode --apple_bitcode=embedded --config=ios_arm64 mediapipe/examples/hand_tracking/ios:HandTracker 2>&1 | tee buildlog-arm64.txt
if [ $? -ne 0 ]; then
  exit 1
fi
set +o pipefail

arm64_build_location=$(cat buildlog-arm64.txt | grep -o 'bazel-out\/.*HandTracker' | head -1)

# The arm64 framework zip will be located at //bazel-bin/mediapipe/examples/hand_tracking/ios/HandTracker.zip

# Call the framework patcher (First argument = compressed framework.zip, Second argument = header file's name(in this case HandTrackingIOSLib.h))
./mediapipe/examples/hand_tracking/ios/patch_ios_framework.sh ./$arm64_build_location.zip HandTracker.h

# There will be a resulting patched .framework folder at the same directory, this is our arm64 one, we copy it to our arm64 folder
echo "Copying from $arm64_build_location"
cp -a ./$arm64_build_location.framework ./frameworkbuild/HandTracker/arm64


# =======================================
# build the arm64 simulator binary framework

echo ""
echo ""
echo "=================================="
echo "BUILDING ios_sim_arm64 FRAMEWORK"
echo "=================================="

set -o pipefail
bazel build --color=yes --copt=-fembed-bitcode --apple_bitcode=embedded --config=ios_sim_arm64 mediapipe/examples/hand_tracking/ios:HandTracker 2>&1 | tee buildlog-sim-arm64.txt
if [ $? -ne 0 ]; then
  exit 1
fi
set +o pipefail

arm64_sim_build_location=$(cat buildlog-sim-arm64.txt | grep -o 'bazel-out\/.*HandTracker' | head -1)

# Call the framework patcher (First argument = compressed framework.zip, Second argument = header file's name(in this case HandTrackingIOSLib.h))
./mediapipe/examples/hand_tracking/ios/patch_ios_framework.sh ./$arm64_sim_build_location.zip HandTracker.h

# There will be a resulting patched .framework folder at the same directory, this is our arm64 one, we copy it to our arm64 folder
echo "Copying from $arm64_sim_build_location"
cp -a "./$arm64_sim_build_location.framework" ./frameworkbuild/HandTracker/arm64_sim

# # Do the same for x86_64

# # build x86_64
# bazel build --copt=-fembed-bitcode --apple_bitcode=embedded --config=ios_x86_64 mediapipe/examples/hand_tracking/ios:HandTracker

# # Call the framework patcher
# ./mediapipe/examples/hand_tracking/ios/patch_ios_framework.sh ./bazel-bin/mediapipe/examples/hand_tracking/ios/HandTracker.zip HandTracker.h

# # copy the patched framework to our folder
# cp -a ./bazel-bin/mediapipe/examples/ios/hand_tracking/HandTracker.framework ./frameworkbuild/HandTracker/x86_64

# Create xcframework (because the classic lipo method with normal .framework no longer works (shows Building for iOS Simulator, but the linked and embedded framework was built for iOS + iOS Simulator))

# xcodebuild -create-xcframework \
#   -framework ./frameworkbuild/HandTracker/x86_64/HandTracker.framework \
#   -framework ./frameworkbuild/HandTracker/arm64/HandTracker.framework \
#   -output ./frameworkbuild/HandTracker/xcframework/HandTracker.xcframework

echo ""
echo ""
echo "=================================="
echo "BUILDING XCFRAMEWORK"
echo "=================================="

# -framework ./frameworkbuild/HandTracker/arm64/HandTracker.framework \
xcodebuild -create-xcframework \
  -framework ./frameworkbuild/HandTracker/arm64/HandTracker.framework \
  -framework ./frameworkbuild/HandTracker/arm64_sim/HandTracker.framework \
  -output ./frameworkbuild/HandTracker/xcframework/HandTracker.xcframework
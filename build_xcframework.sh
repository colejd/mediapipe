#!/bin/sh

rm -rf ./frameworkbuild
mkdir -p ./frameworkbuild/HandTracker/xcframework

# =======================================
# build the xcframework

echo ""
echo "=================================="
echo "BUILDING XCFRAMEWORK"
echo "=================================="

set -o pipefail
bazel build --color=yes --copt=-fembed-bitcode --apple_bitcode=embedded mediapipe/examples/hand_tracking/ios:HandTracker --sandbox_debug
if [ $? -ne 0 ]; then
  exit 1
fi
set +o pipefail

build_location="./bazel-bin/mediapipe/examples/hand_tracking/ios/"

echo "Copying from $build_location"
cp -a ./$build_location/HandTracker.xcframework.zip ./frameworkbuild/HandTracker/xcframework

cd ./frameworkbuild/HandTracker/xcframework
unzip ./HandTracker.xcframework.zip
cd -

# cp -a bazel-bin/mediapipe/examples/hand_tracking/ios/HandTracker.xcframework.zip
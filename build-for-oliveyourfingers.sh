#!/bin/sh

sh ./build_xcframework.sh

if [ $? -ne 0 ]; then
  exit 1
fi

# Copy to known directory that will be checked into iOS repo
cp -a ./frameworkbuild/HandTracker/xcframework/HandTracker.xcframework ../Frameworks

echo "Copied HandTracker.xcframework to ../Frameworks"
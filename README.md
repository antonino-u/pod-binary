# pod-binary

This package will pre-build cocoapods dependencies.
It takes a Pods folder as an input and will output everything needed to use cocoapods dependencis without integrating them as source code into your project. 

Note: you must use the use_frameworks! option in your podfile.

The output folder structure will be XcodeFrameworks, Bundles, UniversalFrameworks, and Libraries. 

These can then be directly added into Xcode and linked against manually. 

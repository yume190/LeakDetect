# Leak Detect

---

A Tool to Detect Swift Potential Leaks

## Installation

``` bash
brew install mint
mint install yume190/LeakDetect
```

## Usage

``` bash
USAGE: command [--verbose] [--mode <mode>]
```

### Environment Variable(Need)

 * `PROJECT_TEMP_ROOT`/`PROJECT_PATH`
 * `TARGET_NAME`

#### Environment Variable(Example)

 * `PROJECT_TEMP_ROOT`="/PATH_TO/DerivedData/TypeFill-abpidkqveyuylveyttvzvsspldln/Build/Intermediates.noindex"
 * `PROJECT_PATH`="/PATH_TO/xxx.xcodeproj" or "/PATH_TO/xxx.xcworkspace"
 * `TARGET_NAME`="Typefill"

> PROJECT_PATH: relative path

> PROJECT_TEMP_ROOT: absolute path

### mode

 * `assign`
 * `capture`

#### Assign

Detect assign instance function `x = self.func` or `y(self.func)`.
see [Don't use this syntax!](https://www.youtube.com/watch?v=mzsz_Tit1HA).

#### Capture

Detect instance captured by blocks(closure/function).

## Example

```sh
git clone https://github.com/antranapp/LeakDetector
cd LeakDetector
# Must build once or use XCode to build
xcodebuild -workspace LeakDetectorDemo.xcworkspace -scheme LeakDetectorDemo -sdk iphonesimulator IPHONEOS_DEPLOYMENT_TARGET=13.0 build
export PROJECT_PATH=LeakDetectorDemo.xcworkspace
export TARGET_NAME=LeakDetectorDemo
leakDetect --mode capture
```
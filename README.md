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
leakDetect \
    --moduleName "SCHEME NAME" \
    --targetType xcworkspace \
    --file Sample.xcworkspace 
    
leakDetect \
    --moduleName "SCHEME NAME" \
    --targetType xcodeproj \
    --file Sample.xcodeproj
```

#### [Assign](LeakDetectKit/Assign/AssignClosureVisitor.swift)

Detect assign instance function.
 
1. `x = self.func`
  [o] Check function is `instance function`.
  [x] Check self is `struct`
2. `y(self.func)`
  [o] Check function is `instance function`.
  [x] Check parameter is `escaping closure`

see [Don't use this syntax!](https://www.youtube.com/watch?v=mzsz_Tit1HA). 

```swift
func escape(block: @escaping () -> Void) {}
class Temp {
  func instanceFunction() {}
  func leak() {
    let x = self.instanceFunction
    escape(block: self.instanceFunction)
  }
}
```

#### Capture

Detect instance captured by blocks(closure/function).

## Example

```sh
# Example:
git clone https://github.com/antranapp/LeakDetector
cd LeakDetector

leakDetect \
    --module LeakDetectorDemo \
    --targetType xcworkspace \
    --file LeakDetectorDemo.xcworkspace

# Mode:
# * assign: detecting assign instance function `x = self.func` or `y(self.func)`.
# * capture: detecting capture instance in closure.
```

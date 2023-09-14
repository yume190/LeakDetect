# Leak Detect

---

一個偵測 swift 潛在 leaks 的小工具

## 安裝

``` bash
brew install mint
mint install yume190/LeakDetect
```

## 使用方式

``` bash
leakDetect \
    --module "SCHEME NAME" \
    --file Sample.xcworkspace

leakDetect \
    --module "SCHEME NAME" \
    --file Sample.xcodeproj

# spm
leakDetect \
    --module TARGET_NAME \
    --file .

# file
leakDetect \
    --sdk macosx \
    --file xxx.swift
```

## Usage(Github Action)

```yaml
jobs:
  build:

    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3
    - uses: yume190/LeakDetect@0.0.8
      with:
        # https://github.com/antranapp/LeakDetector
        module: LeakDetectorDemo
        file: LeakDetectorDemo.xcworkspace
        token: ${{secrets.GITHUB_TOKEN}}
```

---

## Skip List

預設路徑位於 `.leakdetect.yml`, 或者可以使用 `--skip list.yml`.

```yaml
functions:
  # objc function `Dispatch.DispatchQueue.main.async {...}`
  - module: Dispatch
    types:
    - name: DispatchQueue
      instance_functions:
      - async
      - asyncAfter
  # static function `UIKit.UIView.UIView.anmiate {...}`
  - module: UIKit.UIView
    types:
    - name: UIView
      static_functions:
      - animate
  # Some Special case
  - module: YOUR_MODULE_NAME
    types:
    # global function `func escape(...) {}`
    - name: ""
      instance_functions:
      - escape
    # constructor `struct A {...}`
    # A(...) {}
    - name: A
      static_functions:
      - init
    # Nested Type A.B
    - name: A.B
    # Generic Type C<T>.D<U>
    # ignore generic
    - name: C.D
```

### Mode

#### [Assign](LeakDetectKit/Assign/AssignClosureVisitor.swift)

偵測 assign `instance function`.
1. `x = self.func`
   - [x] 檢查 function 是 `instance function`.
   - [ ] 檢查 self 是 `struct`

2. `y(self.func)`
   - [x] 檢查 function 是 `instance function`.
   - [ ] 檢查參數是 `escaping closure`

詳細請參考 [Don't use this syntax!](https://www.youtube.com/watch?v=mzsz_Tit1HA)

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

偵測在 closure 內，被 capture 的 instance

## Example

```sh
# Example:
git clone https://github.com/antranapp/LeakDetector
cd LeakDetector

leakDetect \
    --module LeakDetectorDemo \
    --file LeakDetectorDemo.xcworkspace
```

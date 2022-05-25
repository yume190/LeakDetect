## 建立多個 xpc 服務

https://stackoverflow.com/questions/14035754/running-multiple-instances-of-the-same-xpc-service-nsxpcconnection

## obj leak 範圍

```swift
func xxx() {
    // ...
    // self offset at xxx
    //                ^
}

var xxx: XXX {
    // ...
    // self offset at xxx
    //                ^
}

// closure
{ [weak self] a, b in
    // self offset at [weak self]
    //                      ^
}
```

### 目標

 * `xxx()`
   function call or call closure
 * `xxx.yyy()`
   function call or call closure
 * `XXX()`
   Initial

```swift
func xxx() {
    abc.xxx()
//  ^
    abc.xxx
//  ^
}
```

### 例外

```swift
XCTAssertEqual(code.kind, .refVarGlobal)
XCTAssertEqual(code.kind, .refVarStatic)
```

## obj ref function leak 目標

```swift
xxx(obj.f)
```

----

## 重要


skip type
    typeusr `$sSaySSGD`, `Swift.Array<Swift.String>`
    typeusr `$sSo17OS_dispatch_groupCD`, `__C.OS_dispatch_group`
    typeusr `$sSo6CBUUIDCD`, `__C.CBUUID`
    特殊 typealias
    let cell: DeviceCell = tableView.dequeue(cell: Cell.self, for: indexPath)
skip
    closure

＃ 盲點

1. default skip function
    應該沒事？
2. skip nonescaping closure
    `nonescaping closure` 會被 skip
    實際上應該往上傳遞給 `nonescaping closure` 的 `parent closure` 檢查
    應該要？

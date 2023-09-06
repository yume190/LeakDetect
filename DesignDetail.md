# Design Detail

---

### `key.offset`

> `key.offset` is a reference(file offset) from origin instance. By `SourceKit`.

### Example `key.offset`

```swift
func xxx() {
    let xxx = XXX()
//      ^ <─────────────┐
    // closure          │
    { [weak self, yyy = xxx] _ in
//          ^     ^
//          │     └──── yyy
//          └──── self
    }
}
```

### The `self`'s `key.offset`

```swift
class XXX {
    func xxx() {
//       ^
//       └────┐
        print(self)
    }

    lazy var yyy: Int = {
//           ^
//           └┐
        print(self)
        return 1
    }()

    var zzz: XXX {
//               ^
//            ┌──┘
        print(self)
    }
}
```

---

## Targets

 * Blocks
    * closure blocks
    * function blocks
 * ID

### Find Blocks. By `SwiftSyntax`

```swift
func xxx() {
//         ^
}

var xxx: XXX {
//           ^
}

    { [weak self, yyy = xxx] _ in
//  ^
    }
```

### Find ID(`IdentifierExprSyntax`). By `SwiftSyntax`

```swift
func xxx() {
    abc.xxx()
//  ^
    abc.xxx
//  ^
    XXX()
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

## TODO

 * ignore `defer` block
 * yaml setting
    * skip function
    * skip type
 * refine skip function impl

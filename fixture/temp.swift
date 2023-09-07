import Foundation

func escape(block: @escaping () -> Void) {
}

func nonescape(block: () -> Void) {
}

class A {
    func leak() {
        let a = A()
        let b = A()
        escape {
            print(a)
        }

        nonescape {
            let block = {
                print(a)
            }
        }

        nonescape {
            escape { [b = a] in
                print(a, b)
            }
        }

        struct AA {
            func leak() {
                let aa = AA ()
                escape {
                    print(aa)
                }
            }
        }
    }
}

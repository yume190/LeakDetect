import Foundation

func escape(block: @escaping () -> Void) {
}

func nonescape(block: () -> Void) {
}

class A {
    func leak() {
        let a = A ()
        escape {
            print(a)
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

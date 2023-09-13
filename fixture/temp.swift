import Foundation

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

        escape2 {
            nonescape {
                escape { [b = a] in
                    print(a, b)
                }
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

func escape(block: @escaping () -> Void) {}
func escape2(block: @escaping () -> Void) {}
func nonescape(block: () -> Void) {}

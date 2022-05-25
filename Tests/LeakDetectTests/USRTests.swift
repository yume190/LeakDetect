//
//  File.swift
//  
//
//  Created by Yume on 2022/5/23.
//

import Foundation
import XCTest
@testable import Cursor
@testable import LeakDetectKit

final class USRTests: XCTestCase {
    // 12
    // 2 1_6 2_19
    //         6
    func testStruct() throws {
        /// Vendor.DeviceWiFiAPSetupVC.WiFiInfo`
        /// $s 6Vendor 19DeviceWiFiAPSetupVC C0cD 4Info VD
        ///            ^C                         ^S
        XCTAssertTrue("$s6Vendor19DeviceWiFiAPSetupVCC0cD4InfoVD".isStruct)
        XCTAssertTrue("$s14VendorDatabase16DBBindingRecoverVD".isStruct)
        
        XCTAssertFalse("$s7RxRelay08BehaviorB0CySo7UIImageCSgGD".isStruct)
        
        
        XCTAssertTrue("$s4main3BBBVmD".isStruct)
        XCTAssertTrue("$s4main4BBBBVyAA3BBBVGD".isStruct)
        XCTAssertTrue("$s7RxSwift11AnyObserverVy10Foundation4DataVGD".isStruct)
    }
}
    

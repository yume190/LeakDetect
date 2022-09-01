//
//  FunctionTests.swift
//  
//
//  Created by Yume on 2022/6/2.
//

import Foundation
import HumanString
@testable import LeakDetectKit
@testable import SKClient
import XCTest

final class FunctionTests: XCTestCase {
    final func testObjFunction() throws {
        let code = """
        import UIKit
        
        func test() {
            let queue = DispatchQueue(label: "test")
            queue.async {
        
            }
            DispatchQueue.main.async {
        
            }
            UIView.animate(withDuration: 1) {
        
            }
        }
        """
        
        let client = try SKClient(code: code, arguments: SDK.iphoneos.pathArgs + [
            "-target",
            "arm64-apple-ios11.0",
        ])
        try prepare(client: client) { client in
//            - value : "async(group:qos:flags:execute:)"
//            - value : "source.lang.swift.ref.function.method.instance"
            
            /// queue
            let queue = try client(83)
            print(queue.raw)
            XCTAssertEqual(code[83...87], "async")
            
            
            /// main
            let main = try client(121)
            XCTAssertEqual(code[121...125], "async")
            
            
            let animate = try client(147)
            
            print(animate)
        }
    }

//    (lldb) po queue
//    ▿ SourceKitResponse
//      ▿ raw : 15 elements
//        ▿ 0 : 2 elements
//          - key : "key.containertypeusr"
//          - value : "$sSo17OS_dispatch_queueCD"
//        ▿ 1 : 2 elements
//          - key : "key.typename"
//          - value : "(DispatchQueue) -> (DispatchGroup?, DispatchQoS, DispatchWorkItemFlags, @escaping @convention(block) () -> ()) -> ()"
//        ▿ 2 : 2 elements
//          - key : "key.typeusr"
//          - value : "$s5group3qos5flags7executeySo012OS_dispatch_A0CSg_8Dispatch0G3QoSVAH0G13WorkItemFlagsVyyXLtcD"
//        ▿ 3 : 2 elements
//          - key : "key.related_decls"
//          ▿ value : 2 elements
//            ▿ 0 : 1 element
//              ▿ 0 : 2 elements
//                - key : "key.annotated_decl"
//                - value : "<RelatedName usr=\"s:So17OS_dispatch_queueC8DispatchE5async7executeyAC0D8WorkItemC_tF\">async(execute:)</RelatedName>"
//            ▿ 1 : 1 element
//              ▿ 0 : 2 elements
//                - key : "key.annotated_decl"
//                - value : "<RelatedName usr=\"s:So17OS_dispatch_queueC8DispatchE5async5group7executeySo0a1_b1_F0C_AC0D8WorkItemCtF\">async(group:execute:)</RelatedName>"
//        ▿ 4 : 2 elements
//          - key : "key.usr"
//          - value : "s:So17OS_dispatch_queueC8DispatchE5async5group3qos5flags7executeySo0a1_b1_F0CSg_AC0D3QoSVAC0D13WorkItemFlagsVyyXLtF"
//        ▿ 5 : 2 elements
//          - key : "key.annotated_decl"
//          - value : "<Declaration>func async(group: <Type usr=\"c:objc(cs)OS_dispatch_group\">DispatchGroup</Type>? = nil, qos: <Type usr=\"s:8Dispatch0A3QoSV\">DispatchQoS</Type> = .unspecified, flags: <Type usr=\"s:8Dispatch0A13WorkItemFlagsV\">DispatchWorkItemFlags</Type> = [], execute work: @escaping @convention(block) () -&gt; <Type usr=\"s:s4Voida\">Void</Type>)</Declaration>"
//        ▿ 6 : 2 elements
//          - key : "key.is_dynamic"
//          - value : true
//        ▿ 7 : 2 elements
//          - key : "key.is_system"
//          - value : true
//        ▿ 8 : 2 elements
//          - key : "key.receivers"
//          ▿ value : 1 element
//            ▿ 0 : 1 element
//              ▿ 0 : 2 elements
//                - key : "key.usr"
//                - value : "c:objc(cs)OS_dispatch_queue"
//        ▿ 9 : 2 elements
//          - key : "key.name"
//          - value : "async(group:qos:flags:execute:)"
//        ▿ 10 : 2 elements
//          - key : "key.kind"
//          - value : "source.lang.swift.ref.function.method.instance"
//        ▿ 11 : 2 elements
//          - key : "key.fully_annotated_decl"
//          - value : "<decl.function.method.instance><syntaxtype.keyword>func</syntaxtype.keyword> <decl.name>async</decl.name>(<decl.var.parameter><decl.var.parameter.argument_label>group</decl.var.parameter.argument_label>: <decl.var.parameter.type><ref.class usr=\"c:objc(cs)OS_dispatch_group\">DispatchGroup</ref.class>?</decl.var.parameter.type> = nil</decl.var.parameter>, <decl.var.parameter><decl.var.parameter.argument_label>qos</decl.var.parameter.argument_label>: <decl.var.parameter.type><ref.struct usr=\"s:8Dispatch0A3QoSV\">DispatchQoS</ref.struct></decl.var.parameter.type> = .unspecified</decl.var.parameter>, <decl.var.parameter><decl.var.parameter.argument_label>flags</decl.var.parameter.argument_label>: <decl.var.parameter.type><ref.struct usr=\"s:8Dispatch0A13WorkItemFlagsV\">DispatchWorkItemFlags</ref.struct></decl.var.parameter.type> = []</decl.var.parameter>, <decl.var.parameter><decl.var.parameter.argument_label>execute</decl.var.parameter.argument_label> <decl.var.parameter.name>work</decl.var.parameter.name>: <syntaxtype.keyword>@escaping</syntaxtype.keyword> <decl.var.parameter.type><syntaxtype.attribute.builtin><syntaxtype.attribute.name>@convention</syntaxtype.attribute.name>(block)</syntaxtype.attribute.builtin> () -&gt; <decl.function.returntype><ref.typealias usr=\"s:s4Voida\">Void</ref.typealias></decl.function.returntype></decl.var.parameter.type></decl.var.parameter>)</decl.function.method.instance>"
//        ▿ 12 : 2 elements
//          - key : "key.decl_lang"
//          - value : "source.lang.swift"
//        ▿ 13 : 2 elements
//          - key : "key.doc.full_as_xml"
//          - value : "<Function><Name>async(group:qos:flags:execute:)</Name><USR>s:So17OS_dispatch_queueC8DispatchE5async5group3qos5flags7executeySo0a1_b1_F0CSg_AC0D3QoSVAC0D13WorkItemFlagsVyyXLtF</USR><Declaration>func async(group: DispatchGroup? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -&gt; Void)</Declaration><CommentParts><Abstract><Para>Submits a work item to a dispatch queue and optionally associates it with a dispatch group. The dispatch group may be used to wait for the completion of the work items it references.</Para></Abstract><Parameters><Parameter><Name>group</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>the dispatch group to associate with the submitted work item. If this is <codeVoice>nil</codeVoice>, the work item is not associated with a group.</Para></Discussion></Parameter><Parameter><Name>flags</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>flags that control the execution environment of the</Para></Discussion></Parameter><Parameter><Name>qos</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>the QoS at which the work item should be executed. Defaults to <codeVoice>DispatchQoS.unspecified</codeVoice>.</Para></Discussion></Parameter><Parameter><Name>flags</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>flags that control the execution environment of the work item.</Para></Discussion></Parameter><Parameter><Name>execute</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>The work item to be invoked on the queue.</Para></Discussion></Parameter></Parameters><Discussion><See><Para><codeVoice>sync(execute:)</codeVoice></Para></See><See><Para><codeVoice>DispatchQoS</codeVoice></Para></See><See><Para><codeVoice>DispatchWorkItemFlags</codeVoice></Para></See></Discussion></CommentParts></Function>"
//        ▿ 14 : 2 elements
//          - key : "key.modulename"
//          - value : "Dispatch"
}

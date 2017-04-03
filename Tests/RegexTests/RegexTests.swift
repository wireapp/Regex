//===--- RegexTests.swift -------------------------------------------------===//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===----------------------------------------------------------------------===//

import XCTest
import Regex

class RegexTests: XCTestCase {
    static let pattern:String = "(.+?)([1,2,3]*)(.*)"
    let regex:RegexProtocol = try! Regex(pattern:RegexTests.pattern, groupNames:"letter", "digits", "rest")
    let source = "l321321alala"
    let letter = "l"
    let digits = "321321"
    let rest = "alala"
    let replaceAllTemplate = "$1-$2-$3"
    let replaceAllResult = "l-321321-alala"
    
    let names = "Harry Trump ;Fred Barney; Helen Rigby ; Bill Abel ;Chris Hand"
    let namesSplitPattern = "\\s*;\\s*";
    let splitNames = ["Harry Trump", "Fred Barney", "Helen Rigby", "Bill Abel", "Chris Hand"]
    
    func testMatches() {
        XCTAssert(regex.matches(source))
        XCTAssert(source =~ regex)
        XCTAssert(source =~ RegexTests.pattern)
        
        XCTAssertFalse(source !~ regex)
        XCTAssertFalse(source !~ RegexTests.pattern)
    }
    
    func testSwitch() {
        let exp1 = self.expectation(description: "alpha works")
        switch letter {
            case "\\d".r: XCTFail("letter should not match a digit")
            case "[a-z]".r: exp1.fulfill()
            default: XCTFail("letter should have matched alpha")
        }
        
        let exp2 = self.expectation(description: "alpha works")
        switch digits {
            case "[a-z]+".r: XCTFail("digits should not match letters")
            case "[A-Z]+".r: XCTFail("digits should not match capital letters")
            default: exp2.fulfill()
        }
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testSimple() {
        XCTAssertEqual(RegexTests.pattern.r?.findFirst(in: source)?.group(at: 2), digits)
    }
    
    func _test(group name:String, reference:String) {
        let matches = regex.findAll(in: source)
        for match in matches {
            let value = match.group(named: name)
            XCTAssertEqual(value, reference)
        }
    }
    
    func testLetter() {
        _test(group: "letter", reference: letter)
    }
    
    func testDigits() {
        _test(group: "digits", reference: digits)
    }
    
    func testRest() {
        _test(group: "rest", reference: rest)
    }
    
    func testFirstMatch() {
        let match = regex.findFirst(in: source)
        XCTAssertNotNil(match)
        if let match = match {
            XCTAssertEqual(letter, match.group(named: "letter"))
            XCTAssertEqual(digits, match.group(named: "digits"))
            XCTAssertEqual(rest, match.group(named: "rest"))
            
            XCTAssertEqual(source, match.matched)
            
            let subgroups = match.subgroups
            
            XCTAssertEqual(letter, subgroups[0])
            XCTAssertEqual(digits, subgroups[1])
            XCTAssertEqual(rest, subgroups[2])
        } else {
            XCTFail("Bad test, can not reach this path")
        }
    }
    
    func testReplaceAll() {
        let replaced = regex.replaceAll(in: source, with: replaceAllTemplate)
        XCTAssertEqual(replaceAllResult, replaced)
    }
    
    func testReplaceAllWithReplacer() {
        let replaced = "(.+?)([1,2,3]+)(.+?)".r?.replaceAll(in: "l321321la321a") { match in
            if match.group(at: 1) == "l" {
                return nil
            } else {
                return match.matched.uppercased()
            }
        }
        XCTAssertEqual("l321321lA321A", replaced)
    }
    
    func testReplaceFirst() {
        let replaced = "(.+?)([1,2,3]+)(.+?)".r?.replaceFirst(in: "l321321la321a", with: "$1-$2-$3-")
        XCTAssertEqual("l-321321-l-a321a", replaced)
    }
    
    func testReplaceFirstWithReplacer() {
        let replaced1 = "(.+?)([1,2,3]+)(.+?)".r?.replaceFirst(in: "l321321la321a") { match in
            return match.matched.uppercased()
        }
        XCTAssertEqual("L321321La321a", replaced1)
        
        let replaced2 = "(.+?)([1,2,3]+)(.+?)".r?.replaceFirst(in: "l321321la321a") { match in
            return nil
        }
        XCTAssertEqual("l321321la321a", replaced2)
    }
    
    func testSplit() {
        let re = namesSplitPattern.r!
        let nameList = re.split(names)
        XCTAssertEqual(nameList, splitNames)
    }
    
    func testSplitOnString() {
        let nameList = names.split(using: namesSplitPattern.r)
        XCTAssertEqual(nameList, splitNames)
    }
    
    func testSplitWithSubgroups() {
        let myString = "Hello 1 word. Sentence number 2."
        let splits = myString.split(using: "(\\d)".r)
        XCTAssertEqual(splits, ["Hello ", "1", " word. Sentence number ", "2", "."])
    }
    
    func testNonExistingGroup() {
        let PATH_REGEXP = [
            // Match escaped characters that would otherwise appear in future matches.
            // This allows the user to escape special characters that won't transform.
            "(\\\\.)",
            // Match Express-style parameters and un-named parameters with a prefix
            // and optional suffixes. Matches appear as:
            //
            // "/:test(\\d+)?" => ["/", "test", "\d+", undefined, "?", undefined]
            // "/route(\\d+)"  => [undefined, undefined, undefined, "\d+", undefined, undefined]
            // "/*"            => ["/", undefined, undefined, undefined, undefined, "*"]
            "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^()])+)\\))?|\\(((?:\\\\.|[^()])+)\\))([+*?])?|(\\*))"
            ].joined(separator: "|").r!
        
        let match = PATH_REGEXP.findFirst(in: "/:test(\\d+)?")!
        
        XCTAssertNil(match.group(at: 1))
        XCTAssertNotNil(match.group(at: 2))
    }
}

#if os(Linux)
extension RegexTests {
	static var allTests : [(String, (RegexTests) -> () throws -> Void)] {
		return [
			("testMatches", testMatches),
			("testSwitch", testSwitch),
			("testSimple", testSimple),
			("testLetter", testLetter),
			("testDigits", testDigits),
			("testRest", testRest),
			("testFirstMatch", testFirstMatch),
			("testReplaceAll", testReplaceAll),
			("testReplaceAllWithReplacer", testReplaceAllWithReplacer),
			("testReplaceFirst", testReplaceFirst),
			("testReplaceFirstWithReplacer", testReplaceFirstWithReplacer),
			("testSplit", testSplit),
			("testSplitOnString", testSplitOnString),
			("testSplitWithSubgroups", testSplitWithSubgroups),
			("testNonExistingGroup", testNonExistingGroup),
		]
	}
}
#endif

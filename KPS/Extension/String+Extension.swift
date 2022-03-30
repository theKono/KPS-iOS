//
//  String+Extension.swift
//  KPS-iOS
//
//  Created by mingshing on 2021/12/15.
//

import Foundation

extension String {
    var withoutHtmlTags: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&[^;]+;", with: "", options:.regularExpression, range: nil)
    }
    
    var isSymbol: Bool {
        let symbolSet: Set<String> = [",", "!",".","?", "–",":"]
        
        return symbolSet.contains(self)
    }
    
    var isHTMLTag: Bool {
        
        if self.count == 0 {
            return false
        }
        
        return self.withoutHtmlTags.count == 0
    }
    
    func levenshteinDistanceScore(to string: String, ignoreCase: Bool = true) -> Float {

        var firstString = self
        var secondString = string

        if ignoreCase {
            firstString = firstString.lowercased()
            secondString = secondString.lowercased()
        }
        
        let symbolSet: Set<Character> = [",", "!",".","?", "–",":"]
        firstString.removeAll(where: {symbolSet.contains($0)})
        secondString.removeAll(where: {symbolSet.contains($0)})

        let empty = [Int](repeating:0, count: secondString.count)
        var last = [Int](0...secondString.count)

        for (i, tLett) in firstString.enumerated() {
            var cur = [i + 1] + empty
            for (j, sLett) in secondString.enumerated() {
                cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j])+1
            }
            last = cur
        }

        // maximum string length between the two
        let lowestScore = max(firstString.count, secondString.count)

        if let validDistance = last.last {
            return  1 - (Float(validDistance) / Float(lowestScore))
        }

        return 0.0
    }
}

infix operator =~
func =~(string: String, otherString: String) -> Bool {
    return string.levenshteinDistanceScore(to: otherString) >= 0.75
}

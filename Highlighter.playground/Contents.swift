
import UIKit
import Foundation


// MARK: - App Scope


class Highlighter {
    
    static func highlight(_ tokens: [String], in text: String, maxCount: Int) -> NSAttributedString? {
        print("execute")
        let matches = Highlighter.ranges(of: tokens, in: text)
        if matches.count > 0 {
            let unionizedMatches = Highlighter.union(of: matches)
            let sortedMatches = Highlighter.sort(unionizedMatches)
            if let firstMatch = sortedMatches.first {
                let snippet = Highlighter.snip(text, around: firstMatch, maxCount: maxCount)
                let highlightedSentence = Highlighter.highlight(sortedMatches, in: text, with: snippet)
                return highlightedSentence
            }
        }
        return nil
    }
    
    private static func ranges(of token: String, in text: String) -> [Range<String.Index>] {
        print("match")
        var matchingRanges = [Range<String.Index>]()
        var searchWindowLeft = text.startIndex
        let searchWindowRight = text.endIndex
        
        while searchWindowLeft < searchWindowRight {
            let window = searchWindowLeft..<searchWindowRight
            if let matchingRange = text.range(of: token, options: .caseInsensitive, range: window, locale: nil) {
                matchingRanges.append(matchingRange)
                searchWindowLeft = matchingRange.upperBound
            } else {
                break
            }
        }
        return matchingRanges
    }

    private static func ranges(of tokens: [String], in text: String) -> [Range<String.Index>] {
        print("matchAll")
        var matches = [Range<String.Index>]()
        for token in tokens {
            let match = self.ranges(of: token, in: text)
            if match.isEmpty {
                return []
            } else {
                matches += match
            }
        }
        return matches
    }

    private static func union(of ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        print("merge")
        var merged = [Range<String.Index>]()
        for i in ranges {
            
            var lowerBound = i.lowerBound
            var upperBound = i.upperBound
            for j in ranges {
                if i.overlaps(j) && i != j {
                    lowerBound = i.lowerBound < j.lowerBound ? i.lowerBound : j.lowerBound
                    upperBound = i.upperBound > j.upperBound ? i.upperBound : j.upperBound
                }
            }
            if !merged.contains(lowerBound..<upperBound) {
                merged.append(lowerBound..<upperBound)
            }
        }
        return merged
    }

    private static func sort(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        print("sort")
        return ranges.sorted { (first, second) -> Bool in
            if first.lowerBound == second.lowerBound {
                return first.upperBound < second.upperBound
            }
            return first.lowerBound < second.lowerBound
        }
    }

    private static func highlight(_ ranges: [Range<String.Index>], in text: String, with snippet: Range<String.Index>) -> NSAttributedString {
        print("highlight")
        let attributedText = NSMutableAttributedString(string: text)
        ranges.forEach { range in
            if let font = UIFont(name: "Helvetica", size: 18) {
                let attributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.red,
                    NSAttributedString.Key.font: font
                ]
                attributedText.addAttributes(attributes, range: NSRange(range, in: text))
            }
        }
        
        let result = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: NSRange(snippet, in: text)))
        if snippet.lowerBound != text.startIndex {
            result.insert(NSMutableAttributedString(string: "..."), at: 0)
        }
        
        if snippet.upperBound != text.endIndex {
            result.append(NSMutableAttributedString(string: "..."))
        }
        
        return result
    }

    private static func snip(_ text: String, around range: Range<String.Index>, maxCount: Int) -> Range<String.Index> {
        print("snip")
        guard text.count > maxCount else {
            return Range(uncheckedBounds: (lower: text.startIndex, upper: text.endIndex))
        }

        var windowLeft = range.lowerBound
        var windowRight = range.upperBound
        var count = text.distance(from: windowLeft, to: windowRight) + 1
        repeat {
            if windowLeft != text.startIndex && count <= maxCount {
                windowLeft = text.index(windowLeft, offsetBy: -1)
                count += 1
            }
            
            if windowRight != text.endIndex && count <= maxCount {
                windowRight = text.index(windowRight, offsetBy: 1)
                count += 1
            }
            
        } while count <= maxCount
        
        return windowLeft..<windowRight
    }
}

print("------")

let sentence = "Plz 2 snip snip me"
let search = "Plz snip"
let tokens = search.components(separatedBy: .whitespaces).filter { return !$0.isEmpty }
let attributed = Highlighter.highlight(tokens, in: sentence, maxCount: 10)

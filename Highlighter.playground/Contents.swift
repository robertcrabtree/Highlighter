
import UIKit
import Foundation

// MARK: - App Scope


class Highlighter {
    
    let text: String
    let search: String
    let maxCount: Int
    
    init(text: String, search: String, maxCount: Int) {
        self.text = text
        self.search = search
        self.maxCount = maxCount
    }
    
    func execute() -> NSAttributedString? {
        print("execute")
        let tokens = self.tokens(in: search)
        let matches = self.ranges(of: tokens, in: text)
        if matches.count > 0 {
            let unionizedMatches = self.union(of: matches)
            let sortedMatches = self.sort(unionizedMatches)
            if let firstMatch = sortedMatches.first {
                let snippet = self.snip(text, around: firstMatch, maxCount: maxCount)
                let highlightedSentence = highlight(sortedMatches, in: text)
                let snippedHighlightedSentence = highlightedSentence.attributedSubstring(from: NSRange(snippet, in: text))
                return snippedHighlightedSentence
            }
        }
        return nil
    }
    
    func tokens(in text: String) -> [String] {
        print("tokens")
        return text.components(separatedBy: .whitespaces).filter { return !$0.isEmpty }
    }
    
    func ranges(of token: String, in text: String) -> [Range<String.Index>] {
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

    func ranges(of tokens: [String], in text: String) -> [Range<String.Index>] {
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

    func union(of ranges: [Range<String.Index>]) -> [Range<String.Index>] {
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

    func sort(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        print("sort")
        return ranges.sorted { (first, second) -> Bool in
            if first.lowerBound == second.lowerBound {
                return first.upperBound < second.upperBound
            }
            return first.lowerBound < second.lowerBound
        }
    }

    func highlight(_ ranges: [Range<String.Index>], in text: String) -> NSAttributedString {
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
        return attributedText
    }

    func snip(_ text: String, around range: Range<String.Index>, maxCount: Int) -> Range<String.Index> {
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
let search = "Plz snip me"
let highlighter = Highlighter(text: sentence, search: search, maxCount: 10)
let attributed = highlighter.execute()


import UIKit
import Foundation

// MARK: - App Scope


class Highlighter {
    
    let sentence: String
    let search: String
    let maxCount: Int
    
    init(sentence: String, search: String, maxCount: Int) {
        self.sentence = sentence
        self.search = search
        self.maxCount = maxCount
    }
    
    func execute() -> NSAttributedString? {
        print("execute")
        let tokens = self.tokens(in: search)
        let matches = self.rangesOfAll(tokens, in: sentence)
        if matches.count > 0 {
            let mergedMatches = self.merge(ranges: matches)
            let sortedMatches = self.sort(ranges: mergedMatches)
            if let firstMatch = sortedMatches.first {
                let snippet = self.snip(string: sentence, by: firstMatch, maxCount: maxCount)
                let highlightedSentence = highlight(string: sentence, with: sortedMatches)
                let snippedHighlightedSentence = highlightedSentence.attributedSubstring(from: NSRange(snippet, in: sentence))
                return snippedHighlightedSentence
            }
        }
        return nil
    }
    
    func tokens(in string: String) -> [String] {
        print("tokens")
        return string.components(separatedBy: .whitespaces).filter { return !$0.isEmpty }
    }
    
    func rangesOf(_ token: String, in text: String) -> [Range<String.Index>] {
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

    func rangesOfAll(_ tokens: [String], in text: String) -> [Range<String.Index>] {
        print("matchAll")
        var matches = [Range<String.Index>]()
        for token in tokens {
            let match = self.rangesOf(token, in: text)
            if match.isEmpty {
                return []
            } else {
                matches += match
            }
        }
        return matches
    }

    func merge(ranges: [Range<String.Index>]) -> [Range<String.Index>] {
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

    func sort(ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        print("sort")
        return ranges.sorted { (first, second) -> Bool in
            if first.lowerBound == second.lowerBound {
                return first.upperBound < second.upperBound
            }
            return first.lowerBound < second.lowerBound
        }
    }

    func highlight(string: String, with searches: [Range<String.Index>]) -> NSAttributedString {
        print("highlight")
        let attributedString = NSMutableAttributedString(string: string)
        searches.forEach { search in
            if let font = UIFont(name: "Helvetica", size: 18) {
                let attributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.red,
                    NSAttributedString.Key.font: font
                ]
                attributedString.addAttributes(attributes, range: NSRange(search, in: string))
            }
        }
        return attributedString
    }

    func snip(string: String, by range: Range<String.Index>, maxCount: Int) -> Range<String.Index> {
        print("snip")
        guard string.count > maxCount else {
            return Range(uncheckedBounds: (lower: string.startIndex, upper: string.endIndex))
        }

        var windowLeft = range.lowerBound
        var windowRight = range.upperBound
        var count = string.distance(from: windowLeft, to: windowRight) + 1
        repeat {
            if windowLeft != string.startIndex && count <= maxCount {
                windowLeft = string.index(windowLeft, offsetBy: -1)
                count += 1
            }
            
            if windowRight != string.endIndex && count <= maxCount {
                windowRight = string.index(windowRight, offsetBy: 1)
                count += 1
            }
            
        } while count <= maxCount
        
        return windowLeft..<windowRight
    }
}

print("------")

let sentence = "Plz 2 snip snip me"
let search = "Plz snip me"
let highlighter = Highlighter(sentence: sentence, search: search, maxCount: 10)
let attributed = highlighter.execute()

import SwiftUI

/// Swift source with Xcode's dark-theme colours.
struct CodeView: View {
    let code: String
    var size: CGFloat = 15
    /// Off for code on draggable tiles, where selection would swallow the drag.
    var selectable = true

    var body: some View {
        Group {
            if selectable {
                text.textSelection(.enabled)
            } else {
                text
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.displayP3, red: 0.10, green: 0.10, blue: 0.13), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.hairline)
            }
            .accessibilityLabel(code)
    }

    private var text: some View {
        Text(SwiftHighlighter.highlight(code))
            .font(.system(size: size, design: .monospaced))
            .lineSpacing(3)
    }
}

/// A small tokenizer: enough to colour keywords, types, strings, numbers, attributes and comments.
enum SwiftHighlighter {
    static let keyword = Color(.displayP3, red: 0.99, green: 0.37, blue: 0.64)
    static let type = Color(.displayP3, red: 0.36, green: 0.85, blue: 1.00)
    static let string = Color(.displayP3, red: 0.99, green: 0.42, blue: 0.36)
    static let number = Color(.displayP3, red: 0.82, green: 0.75, blue: 0.41)
    static let comment = Color(.displayP3, red: 0.45, green: 0.50, blue: 0.56)
    static let attribute = Color(.displayP3, red: 0.99, green: 0.56, blue: 0.25)
    static let plain = Color.white.opacity(0.92)

    private static let keywords: Set<String> = [
        "let", "var", "func", "struct", "class", "enum", "protocol", "extension", "actor", "return",
        "if", "else", "guard", "switch", "case", "default", "for", "in", "while", "import", "async",
        "await", "throws", "try", "self", "Self", "nil", "true", "false", "private", "public", "final",
        "static", "lazy", "weak", "unowned", "some", "any", "init", "inout", "where", "nonisolated",
        "sending", "borrowing", "consuming", "break", "continue", "defer", "do", "catch", "throw",
    ]

    static func highlight(_ code: String) -> AttributedString {
        var result = AttributedString()
        let chars = Array(code)
        var i = 0

        func append(_ text: String, _ color: Color) {
            var piece = AttributedString(text)
            piece.foregroundColor = color
            result += piece
        }

        while i < chars.count {
            let c = chars[i]
            if c == "/", i + 1 < chars.count, chars[i + 1] == "/" {
                var j = i
                while j < chars.count, chars[j] != "\n" { j += 1 }
                append(String(chars[i..<j]), comment)
                i = j
            } else if c == "\"" {
                var j = i + 1
                while j < chars.count, chars[j] != "\"", chars[j] != "\n" { j += 1 }
                j = min(j + 1, chars.count)
                append(String(chars[i..<j]), string)
                i = j
            } else if c == "@" {
                var j = i + 1
                while j < chars.count, chars[j].isLetter { j += 1 }
                append(String(chars[i..<j]), attribute)
                i = j
            } else if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." && j + 1 < chars.count && chars[j + 1].isNumber { j += 1 }
                append(String(chars[i..<j]), number)
                i = j
            } else if c.isLetter || c == "_" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
                let word = String(chars[i..<j])
                if keywords.contains(word) {
                    append(word, keyword)
                } else if word.first?.isUppercase == true {
                    append(word, type)
                } else {
                    append(word, plain)
                }
                i = j
            } else {
                append(String(c), plain)
                i += 1
            }
        }
        return result
    }
}

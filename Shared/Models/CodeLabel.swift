import Foundation
import SwiftData

// MARK: - CodeLabel

/// A reusable classification shared by one or more code records.
@Model
final class CodeLabel {
    /// The stable identifier of the default Bookmark label.
    ///
    /// Bookmark replaces the legacy favorite flag. It always exists and cannot be edited or deleted.
    static let bookmarkID = UUID(uuidString: "F96C29CB-7ED9-4C1C-A988-4AE7BFF83B20")!

    /// The persistent identity of the label.
    @Attribute(.unique)
    var id: UUID

    /// The optional user-provided title, excluding surrounding whitespace.
    var title: String?

    /// The SF Symbol name selected from the supported icon catalog.
    var symbolName: String

    /// The date the label was created.
    var creationDate: Date

    /// The records classified by this label.
    @Relationship(deleteRule: .nullify, inverse: \CodeRecord.labels)
    var records: [CodeRecord] = []

    /// A Boolean value indicating whether the label is the default Bookmark label.
    var isBookmark: Bool { id == Self.bookmarkID }

    /// The name of the symbol used to display the label, preserving the Bookmark icon.
    var displaySymbolName: String { isBookmark ? "bookmark.fill" : symbolName }

    /// Creates a label with the specified identity and presentation.
    init(
        id: UUID = UUID(),
        title: String? = nil,
        symbolName: String = LabelSymbol.defaultSymbolName,
        creationDate: Date = .now
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.creationDate = creationDate
    }
}

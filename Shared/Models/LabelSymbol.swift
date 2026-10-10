import Foundation

/// A curated SF Symbol with a localized name for label selection.
nonisolated struct LabelSymbol: Identifiable, Sendable {
    /// The SF Symbol name used as the stable catalog identity.
    let id: String
    /// The localized name displayed in the icon picker.
    let name: LocalizedStringResource

    /// A group of symbols organized by their intended use.
    enum Category: String, CaseIterable, Identifiable {
        case common, life, work, travel, entertainment
        var id: String { rawValue }
        var title: LocalizedStringResource {
            switch self {
            case .common: "Common"
            case .life: "Everyday"
            case .work: "Work"
            case .travel: "Travel"
            case .entertainment: "Entertainment"
            }
        }
        var symbols: [LabelSymbol] {
            switch self {
            case .common: [
                LabelSymbol(id: "tag.fill", name: "Label"),
                LabelSymbol(id: "star.fill", name: "Star"),
                LabelSymbol(id: "bookmark.fill", name: "Bookmark"),
                LabelSymbol(id: "pin.fill", name: "Pin"),
                LabelSymbol(id: "flag.fill", name: "Flag"),
                LabelSymbol(id: "bolt.fill", name: "Quick Access")
            ]
            case .life: [
                LabelSymbol(id: "house.fill", name: "Home"),
                LabelSymbol(id: "cart.fill", name: "Shopping"),
                LabelSymbol(id: "creditcard.fill", name: "Card"),
                LabelSymbol(id: "gift.fill", name: "Gift"),
                LabelSymbol(id: "fork.knife", name: "Food"),
                LabelSymbol(id: "cross.case.fill", name: "Health")
            ]
            case .work: [
                LabelSymbol(id: "briefcase.fill", name: "Office"),
                LabelSymbol(id: "person.2.fill", name: "People"),
                LabelSymbol(id: "building.2.fill", name: "Business"),
                LabelSymbol(id: "doc.fill", name: "Document"),
                LabelSymbol(id: "calendar", name: "Calendar"),
                LabelSymbol(id: "link", name: "Link")
            ]
            case .travel: [
                LabelSymbol(id: "airplane", name: "Flight"),
                LabelSymbol(id: "car.fill", name: "Car"),
                LabelSymbol(id: "tram.fill", name: "Train"),
                LabelSymbol(id: "bus.fill", name: "Bus"),
                LabelSymbol(id: "map.fill", name: "Map"),
                LabelSymbol(id: "bed.double.fill", name: "Hotel")
            ]
            case .entertainment: [
                LabelSymbol(id: "ticket.fill", name: "Ticket"),
                LabelSymbol(id: "film.fill", name: "Movie"),
                LabelSymbol(id: "music.note", name: "Music"),
                LabelSymbol(id: "gamecontroller.fill", name: "Game"),
                LabelSymbol(id: "book.fill", name: "Book"),
                LabelSymbol(id: "sportscourt.fill", name: "Sport")
            ]
            }
        }
    }

    /// The symbol name used for new labels.
    static let defaultSymbolName = "tag.fill"

    /// The complete supported symbol catalog in display order.
    static let catalog = Category.allCases.flatMap(\.symbols)

    /// Returns the localized name of a catalog symbol, falling back to a generic label name.
    ///
    /// - Parameter symbolName: The SF Symbol name to look up.
    static func localizedName(forSymbolName symbolName: String) -> LocalizedStringResource {
        catalog.first { $0.id == symbolName }?.name ?? "Label"
    }
}

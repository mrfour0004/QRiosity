import Foundation
import SwiftData
import WidgetKit

// MARK: - LabelStore

/// Operations that preserve label, Bookmark, and History invariants.
///
/// Successful mutations save the context and request widget timeline updates.
/// Failed mutations roll back the context; callers should keep unrelated drafts
/// outside the context until they are ready to commit.
@MainActor
enum LabelStore {
    // MARK: - ValidationError

    /// A reason a label operation was rejected before changing any data.
    enum ValidationError: LocalizedError, Equatable {
        /// The operation would edit or delete the default Bookmark label.
        case bookmarkLabel
        /// Another label already has the same title, or the same symbol when neither has a title.
        case duplicate
        /// The symbol is not in ``LabelSymbol/catalog``.
        case invalidSymbol

        var errorDescription: String? {
            switch self {
            case .bookmarkLabel: String(localized: "The Bookmark label cannot be changed or deleted.")
            case .duplicate: String(localized: "This label already exists. Choose a different title.")
            case .invalidSymbol: String(localized: "Choose an icon from the list.")
            }
        }
    }

    /// Returns the message to show the user for an error thrown by a label operation.
    ///
    /// - Parameter error: The error thrown by a `LabelStore` method.
    /// - Returns: The validation message for a ``ValidationError``, or a generic save-failure message.
    static func message(for error: any Error) -> String {
        (error as? ValidationError)?.errorDescription
            ?? String(localized: "Your changes could not be saved. Please try again.")
    }

    /// Creates or updates a custom label with a validated title and symbol.
    ///
    /// - Parameters:
    ///   - label: The existing label, or `nil` to create one.
    ///   - title: The optional title as entered by the user; whitespace-only titles become `nil`.
    ///   - symbolName: A symbol from ``LabelSymbol/catalog``.
    ///   - context: The context in which to save the label.
    /// - Returns: The saved label.
    /// - Throws: A validation or persistence error.
    @discardableResult
    static func save(
        _ label: CodeLabel? = nil,
        title: String,
        symbolName: String,
        in context: ModelContext
    ) throws -> CodeLabel {
        guard label?.isBookmark != true else { throw ValidationError.bookmarkLabel }
        let labels = try context.fetch(FetchDescriptor<CodeLabel>())
        let title = try validatedTitle(title, symbolName: symbolName, among: labels, excluding: label?.id)
        let result = label ?? CodeLabel()
        try commit(in: context) {
            if label == nil { context.insert(result) }
            result.title = title
            result.symbolName = symbolName
        }
        return result
    }

    /// Returns the title to store for a label after validating its title and symbol.
    ///
    /// The returned title is `title` with leading and trailing whitespace and newlines
    /// removed. A title that is empty after trimming returns `nil`, which represents a
    /// label that shows only its icon.
    ///
    /// A label is a duplicate of another label in `labels` when either:
    /// - Both have titles, and the titles are equal ignoring case and diacritics.
    /// - Neither has a title, and both use the same symbol.
    ///
    /// - Parameters:
    ///   - title: The title as entered by the user, before trimming.
    ///   - symbolName: The name of the selected symbol, which must be in ``LabelSymbol/catalog``.
    ///   - labels: The existing labels to check for duplicates.
    ///   - id: The identity of the label being edited, which is skipped in the duplicate check.
    ///     Pass `nil` when creating a label.
    /// - Returns: The trimmed title, or `nil` if the trimmed title is empty.
    /// - Throws: ``ValidationError/invalidSymbol`` if `symbolName` is not supported, or
    ///   ``ValidationError/duplicate`` if the label duplicates an existing label.
    static func validatedTitle(
        _ title: String,
        symbolName: String,
        among labels: [CodeLabel],
        excluding id: UUID? = nil
    ) throws -> String? {
        guard LabelSymbol.catalog.contains(where: { $0.id == symbolName }) else { throw ValidationError.invalidSymbol }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String? = trimmed.isEmpty ? nil : trimmed
        let duplicate = labels.contains { existing in
            guard existing.id != id else { return false }
            if let title, let existingTitle = existing.title {
                return title.compare(existingTitle, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            return title == nil && existing.title == nil && existing.symbolName == symbolName
        }
        guard !duplicate else { throw ValidationError.duplicate }
        return title
    }

    /// Replaces a record's labels and saves any newly selected draft labels.
    ///
    /// Removing the last label restores the record to History.
    ///
    /// - Parameters:
    ///   - labels: The complete selection, including any unsaved draft labels.
    ///   - record: The record being classified.
    ///   - context: The context that owns the record.
    /// - Throws: A validation or persistence error.
    static func setLabels(_ labels: [CodeLabel], for record: CodeRecord, in context: ModelContext) throws {
        try commit(in: context) {
            var available = try context.fetch(FetchDescriptor<CodeLabel>())
            for label in labels where label.modelContext == nil {
                _ = try validatedTitle(label.title ?? "", symbolName: label.symbolName, among: available)
                context.insert(label)
                available.append(label)
            }
            var seen = Set<UUID>()
            record.labels = labels.filter { seen.insert($0.id).inserted }
            if record.labels.isEmpty { record.isDeletedFromHistory = false }
        }
    }

    /// Deletes a custom label, retaining its records and restoring unlabelled records to History.
    ///
    /// - Throws: An error if the label is Bookmark or persistence fails.
    static func delete(_ label: CodeLabel, in context: ModelContext) throws {
        guard !label.isBookmark else { throw ValidationError.bookmarkLabel }
        try commit(in: context) {
            for record in Array(label.records) {
                record.labels.removeAll { $0.id == label.id }
                if record.labels.isEmpty { record.isDeletedFromHistory = false }
            }
            context.delete(label)
        }
    }

    /// Hides labeled records from History and deletes records without labels.
    ///
    /// - Throws: A persistence error if the changes cannot be saved.
    static func clearHistory(_ records: [CodeRecord], in context: ModelContext) throws {
        try commit(in: context) {
            for record in records {
                if record.hasLabels { record.isDeletedFromHistory = true }
                else { context.delete(record) }
            }
        }
    }

    /// Deletes a record while preserving its labels.
    ///
    /// - Throws: A persistence error if the deletion cannot be saved.
    static func delete(_ record: CodeRecord, in context: ModelContext) throws {
        try commit(in: context) { context.delete(record) }
    }

    private static func commit(in context: ModelContext, changes: () throws -> Void) throws {
        do {
            try context.transaction {
                try changes()
                try context.save()
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            context.rollback()
            throw error
        }
    }
}

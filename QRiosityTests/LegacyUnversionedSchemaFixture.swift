import Foundation
import SwiftData

/// An independent fixture schema copied from the original pre-label model.
///
/// Keep this snapshot unchanged when modifying current or versioned models.
enum LegacyUnversionedSchemaFixture {
    @Model
    final class CodeRecord {
        /// The original persisted description field, retained to reproduce the legacy schema.
        var desc: String?
        var isDeletedFromHistory: Bool = false
        var isFavorite: Bool = false
        var metadataObjectType: String
        var previewImageURLString: String?
        var scannedAt: Date
        var stringValue: String
        var title: String?

        init(stringValue: String, metadataObjectType: String, scannedAt: Date = Date()) {
            self.stringValue = stringValue
            self.metadataObjectType = metadataObjectType
            self.scannedAt = scannedAt
            self.isFavorite = false
            self.isDeletedFromHistory = false
        }
    }
}

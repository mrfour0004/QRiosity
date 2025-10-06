//
//  CodeRecord.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import Alamofire
import AVFoundation
import Foundation
import Kanna
import SwiftData

private typealias OpenGraph = [String: String]

@Model
final class CodeRecord: Identifiable {
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
    
    enum RecordType {
        case url
        case string
    }
    
    var type: RecordType {
        url != nil ? .url : .string
    }
    
    var is2DBarcode: Bool {
        Set(["QRCode", "Aztec", "PDF417"]).contains(metadataObjectType.split(separator: ".").last ?? "")
    }
    
    /// An URL value that the code content represents for. Returns `nil` if the content is not an URL.
    var url: URL? {
        let availableSchemes = ["https", "http"]
        guard
            let url = URL(string: stringValue),
            let scheme = url.scheme, availableSchemes.contains(scheme.lowercased())
        else { return nil }
        
        return url
    }
}

// MARK: - Getting Link Metadata

extension CodeRecord {
    /// Fetches the metadata for the link if barcode content is a URL.
    @MainActor
    func fetchLinkMetadataIfNeeded(modelContext: ModelContext) async {
        guard let url = URL(string: stringValue) else { return }
        
        do {
            let htmlString = try await AF.request(url).serializingString(encoding: .utf8).value
            
            try updateMetadata(with: HTML(html: htmlString, encoding: .utf8))
            try modelContext.save()
        } catch {
            print("Failed to fetch or update metadata: \(error.localizedDescription)")
        }
    }
    
    private func updateMetadata(with doc: HTMLDocument) throws {
        title = doc.title?.trimmed ?? self.stringValue
        
        if title != stringValue {
            desc = stringValue
        }
        
        guard let metaSet = doc.head?.css("meta") else {
            return
        }
        
        var openGraph = OpenGraph()
        for meta in metaSet {
            guard let property = meta["property"]?.lowercased(),
                  property.hasPrefix("og:"),
                  let content = meta["content"]
            else { continue }
            openGraph[property] = content
        }
        
        title = openGraph["og:title"] ?? title
        desc = openGraph["og:description"] ?? desc
        previewImageURLString = openGraph["og:image"]?.trimmed
    }
}

// MARK: - Class function

extension CodeRecord {
    static func create(
        with codeObject: AVMetadataMachineReadableCodeObject,
        in modelContext: ModelContext
    ) -> CodeRecord {
        create(withString: codeObject.stringValue!, type: codeObject.type, in: modelContext)
    }
    
    static func create(
        withString value: String,
        type: AVMetadataObject.ObjectType,
        in modelContext: ModelContext
    ) -> CodeRecord {
        let instance = CodeRecord(
            stringValue: value,
            metadataObjectType: type.rawValue,
            scannedAt: Date()
        )
        
        modelContext.insert(instance)
        return instance
    }
}

// MARK: - Extensions for compatibility

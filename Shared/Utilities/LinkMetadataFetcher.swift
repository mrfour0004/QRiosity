//
//  LinkMetadataFetcher.swift
//  QRiosity
//
//  Created by Claude on 2025/10/10.
//  Copyright © 2025 mrfour. All rights reserved.
//

import Alamofire
import Foundation
import Kanna

struct LinkMetadata {
    let title: String?
    let description: String?
    let previewImageURL: String?
}

enum LinkMetadataFetcher {
    static func fetchMetadata(from url: URL) async throws -> LinkMetadata {
        let htmlString = try await AF.request(url).serializingString(encoding: .utf8).value
        return try parseMetadata(from: htmlString, originalURL: url.absoluteString)
    }
    
    private static func parseMetadata(from htmlString: String, originalURL: String) throws -> LinkMetadata {
        let doc = try HTML(html: htmlString, encoding: .utf8)
        
        var title = doc.title?.trimmed ?? originalURL
        var description: String? = nil
        var previewImageURL: String? = nil
        
        if title != originalURL {
            description = originalURL
        }
        
        guard let metaSet = doc.head?.css("meta") else {
            return LinkMetadata(title: title, description: description, previewImageURL: previewImageURL)
        }
        
        var openGraph: [String: String] = [:]
        for meta in metaSet {
            guard let property = meta["property"]?.lowercased(),
                  property.hasPrefix("og:"),
                  let content = meta["content"]
            else { continue }
            openGraph[property] = content
        }
        
        title = openGraph["og:title"] ?? title
        description = openGraph["og:description"] ?? description
        previewImageURL = openGraph["og:image"]?.trimmed
        
        return LinkMetadata(title: title, description: description, previewImageURL: previewImageURL)
    }
}

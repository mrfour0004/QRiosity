import BarGlyph
import UIKit

nonisolated struct Code39Generator: BarcodeGenerator {
    func generateImage(from content: String) -> UIImage? {
        guard let image = try? BarGlyph.image(
            for: content,
            symbology: .code39,
            options: .init(
                moduleSize: 3,
                barHeight: 240,
                backgroundColor: .init(red: 0, green: 0, blue: 0, alpha: 0)
            )
        ) else {
            return nil
        }

        return UIImage(cgImage: image)
    }
}

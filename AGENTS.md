# Project Guide

## Overview

QRiosity is a SwiftUI iOS app for scanning, generating, saving, and displaying QR codes and barcodes. It also includes a WidgetKit extension that displays favorite records. Develop with `QRiosity.xcodeproj`. The main scheme is `QRiosity`, and the widget scheme is `RecordWidget1DExtension`. The project uses SwiftData; the app target uses Swift 6.0. Check the Xcode project settings for the current minimum iOS version.

## Repository Layout

- `QRiosity/`: App-specific views, configuration, and entitlements.
- `Shared/`: Models, SwiftData persistence, scanner scenes, barcode generators, image storage, and UI components shared by the app and widget. The existing directory is named `Persistance`; do not rename it as part of an unrelated change.
- `RecordWidget/`: WidgetKit views, timelines, App Intents, and record queries.
- `Resources/Localizable.xcstrings`: String catalog for localization.
- `QRiosityTests/` and `QRiosityUITests/`: Unit and UI test targets. Most existing tests are Xcode templates, so passing them does not establish that app behavior is correct.

## Change Guidelines

- Follow the existing SwiftUI, SwiftData, and file organization patterns. Put logic needed by both the app and widget in `Shared/`, and make sure new files belong to the required targets.
- `CodeRecord` is the shared SwiftData model. When changing its fields, queries, or deletion behavior, check history, favorites, record details, and widget reads together.
- The app and widget share data and barcode images through the App Group `group.com.mrfour.test`. Changes to this identifier, entitlements, persistence location, or `BarcodeImageStorage` filenames must account for both targets and existing data.
- Barcode types use AVFoundation raw string values in several places. When adding or changing a supported type, check scanner configuration, `BarcodeGeneratorFactory`, `CodeRecord.is2DBarcode`, and widget filtering and display.
- When adding or changing user-facing text, check `Resources/Localizable.xcstrings`. Keep debug messages and implementation details out of the UI.
- Do not change signing settings, bundle IDs, deployment targets, or dependency versions unless the task requires it.

## Verification

- For Swift changes, build the `QRiosity` scheme in Xcode when possible. A command-line build is:

  ```sh
  xcodebuild -project QRiosity.xcodeproj -scheme QRiosity -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/QRiosityDerivedData CODE_SIGNING_ALLOWED=NO build
  ```

- For widget changes, also build the `RecordWidget1DExtension` scheme and check configuration, displayed data, and refresh behavior on an available simulator or device.
- To run tests, select an installed iOS simulator as the destination. Camera scanning, App Group storage, and widget interaction need appropriate simulator or device checks. State any verification limits in the final report.
- Before finishing, review the diff and report what changed, what was verified, and what remains unverified.

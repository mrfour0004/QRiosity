//
//  PropertyEditView.swift
//  QRiosity
//
//  Created by Claude on 2025/8/30.
//

import SwiftUI
import SwiftData

struct PropertyEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable
    var record: CodeRecord
    let keyPath: ReferenceWritableKeyPath<CodeRecord, String?>
    let propertyName: String

    @State
    private var editingValue: String

    @FocusState
    private var isTextFieldFocused: Bool

    init(record: CodeRecord, keyPath: ReferenceWritableKeyPath<CodeRecord, String?>, propertyName: String) {
        self.record = record
        self.keyPath = keyPath
        self.propertyName = propertyName
        _editingValue = State(initialValue: record[keyPath: keyPath] ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.displayP3, white: 0.96, opacity: 1)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    contentArea

                    Spacer()

                    saveButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                isTextFieldFocused = true
            }
        }
    }

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(propertyName)
                .font(.avenir(.title2))
                .fontWeight(.black)
                .foregroundStyle(.primary)

            HStack {
                TextField("Untitled Code", text: $editingValue)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.avenir(.body).weight(.semibold))
                    .focused($isTextFieldFocused)

                if !editingValue.isEmpty {
                    Button {
                        editingValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.lightGray))
                            .opacity(0.5)
                    }
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: editingValue.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var saveButton: some View {
        HStack {
            Spacer()

            Button {
                saveChanges()
            } label: {
                Label("Save", systemImage: "checkmark")
                    .labelStyle(.iconOnly)
            }
            .controlSize(.extraLarge)
            .font(.avenir(.headline))
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func saveChanges() {
        record[keyPath: keyPath] = editingValue.isEmpty ? nil : editingValue

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error.localizedDescription)")
        }
    }
}

#Preview {
    PropertyEditor(
        record: {
            let newRecord = CodeRecord(stringValue: "https://example.com", metadataObjectType: "QR")
            newRecord.title = "Sample Title"
            return newRecord
        }(),
        keyPath: \.title,
        propertyName: "Title"
    )
    .modelContainer(PersistenceController.preview.modelContainer)
}

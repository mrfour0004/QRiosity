import SwiftData
import SwiftUI

// MARK: - CodeLabelTitle

/// A user-provided label title, falling back to the localized symbol name.
struct CodeLabelTitle: View {
    let label: CodeLabel
    var text: Text {
        if let title = label.title { Text(verbatim: title) }
        else { Text(LabelSymbol.localizedName(forSymbolName: label.symbolName)) }
    }

    var body: some View { text }
}

// MARK: - CodeLabelBadge

/// A label icon paired with its accessible display title.
struct CodeLabelBadge: View {
    let label: CodeLabel

    var body: some View {
        Label {
            CodeLabelTitle(label: label)
        } icon: {
            Image(systemName: label.displaySymbolName)
        }
        .labelStyle(.titleAndIcon)
    }
}

// MARK: - RecordLabelIcons

/// A compact, scrollable summary of a record’s labels.
struct RecordLabelIcons: View {
    let labels: [CodeLabel]
    var body: some View {
        let ordered = labels.sorted { $0.creationDate < $1.creationDate }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ordered) { label in
                    Image(systemName: label.displaySymbolName)
                        .foregroundStyle(label.isBookmark ? Color.accentColor : Color.secondary)
                        .accessibilityLabel(CodeLabelTitle(label: label).text)
                }
            }
        }
        .font(.caption)
    }
}

// MARK: - LabelEditor

/// An editor that commits a custom label only when Save succeeds.
struct LabelEditor: View {
    /// The title and symbol entered in the editor.
    struct Draft {
        /// The title as entered, before trimming; may be empty.
        var title: String
        /// The name of the selected symbol.
        var symbolName: String
    }

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var symbolName: String
    @State private var errorMessage: String?
    let isEditing: Bool
    let onSave: (Draft) throws -> Void

    init(label: CodeLabel? = nil, onSave: @escaping (Draft) throws -> Void) {
        _title = State(initialValue: label?.title ?? "")
        _symbolName = State(initialValue: label?.symbolName ?? LabelSymbol.defaultSymbolName)
        isEditing = label != nil
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: symbolName)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 44, height: 44)
                            .accessibilityLabel(Text(LabelSymbol.localizedName(forSymbolName: symbolName)))
                            .accessibilityIdentifier("labelSelectedSymbol")
                        TextField("Title (optional)", text: $title)
                            .accessibilityIdentifier("labelTitle")
                    }
                }
                SymbolPicker(selection: $symbolName)
            }
            .navigationTitle(isEditing ? Text("Edit Label") : Text("New Label"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onSave(Draft(title: title, symbolName: symbolName))
                            dismiss()
                        } catch {
                            errorMessage = LabelStore.message(for: error)
                        }
                    }
                    .accessibilityIdentifier("saveLabel")
                }
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
    }
}

// MARK: - SymbolPicker

private struct SymbolPicker: View {
    @Binding var selection: String
    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        ForEach(LabelSymbol.Category.allCases) { category in
            Section {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(category.symbols) { symbol in
                        Button {
                            selection = symbol.id
                        } label: {
                            Image(systemName: symbol.id)
                                .font(.title2)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .padding(4)
                                .background(selection == symbol.id ? Color.accentColor.opacity(0.15) : .clear,
                                            in: RoundedRectangle(cornerRadius: 12))
                                .overlay(alignment: .topTrailing) {
                                    if selection == symbol.id {
                                        Image(systemName: "checkmark.circle.fill").font(.caption)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(symbol.name))
                        .accessibilityIdentifier("symbol-\(symbol.id)")
                        .accessibilityAddTraits(selection == symbol.id ? .isSelected : [])
                    }
                }
            } header: { Text(category.title) }
        }
    }
}

// MARK: - LabelSelectionView

/// A draft selection of labels that commits only when Done is selected.
struct LabelSelectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CodeLabel.creationDate) private var labels: [CodeLabel]
    let record: CodeRecord
    @State private var selectedLabelIDs: Set<UUID>
    @State private var pendingLabels: [CodeLabel] = []
    @State private var isCreatingLabel = false
    @State private var errorMessage: String?
    let onSave: () -> Void

    init(record: CodeRecord, onSave: @escaping () -> Void = {}) {
        self.record = record
        _selectedLabelIDs = State(initialValue: Set(record.labels.map(\.id)))
        self.onSave = onSave
    }

    var body: some View {
        let available = labels + pendingLabels
        NavigationStack {
            List {
                ForEach(available) { label in
                    Button {
                        if !selectedLabelIDs.insert(label.id).inserted { selectedLabelIDs.remove(label.id) }
                    } label: {
                        HStack {
                            CodeLabelBadge(label: label)
                            Spacer()
                            if selectedLabelIDs.contains(label.id) { Image(systemName: "checkmark") }
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(selectedLabelIDs.contains(label.id) ? .isSelected : [])
                }
                Button { isCreatingLabel = true } label: {
                    Label("New Label", systemImage: "plus")
                }
            }
            .navigationTitle("Labels")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        do {
                            try LabelStore.setLabels(
                                available.filter { selectedLabelIDs.contains($0.id) },
                                for: record,
                                in: context
                            )
                            onSave()
                            dismiss()
                        } catch {
                            errorMessage = LabelStore.message(for: error)
                        }
                    }
                }
            }
            .sheet(isPresented: $isCreatingLabel) {
                LabelEditor { draft in
                    let normalizedTitle = try LabelStore.validatedTitle(
                        draft.title,
                        symbolName: draft.symbolName,
                        among: available
                    )
                    let label = CodeLabel(title: normalizedTitle, symbolName: draft.symbolName)
                    pendingLabels.append(label)
                    selectedLabelIDs.insert(label.id)
                }
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
    }
}

// MARK: - LabelManagementView

/// A list for creating and managing custom labels alongside the fixed Bookmark label.
struct LabelManagementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CodeLabel.creationDate) private var labels: [CodeLabel]
    @State private var isCreatingLabel = false
    @State private var labelBeingEdited: CodeLabel?
    @State private var labelPendingDeletion: CodeLabel?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(labels) { label in
                    ManagedLabelRow(
                        label: label,
                        onEdit: { labelBeingEdited = label },
                        onDelete: { labelPendingDeletion = label }
                    )
                }
                Button { isCreatingLabel = true } label: { Label("New Label", systemImage: "plus") }
            }
            .navigationTitle("Manage Labels")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $isCreatingLabel) {
                LabelEditor { draft in
                    try LabelStore.save(title: draft.title, symbolName: draft.symbolName, in: context)
                }
            }
            .sheet(item: $labelBeingEdited) { label in
                LabelEditor(label: label) { draft in
                    try LabelStore.save(label, title: draft.title, symbolName: draft.symbolName, in: context)
                }
            }
            .alert("Delete Label?", isPresented: Binding(
                get: { labelPendingDeletion != nil }, set: { if !$0 { labelPendingDeletion = nil } }
            ), presenting: labelPendingDeletion) { label in
                Button("Delete", role: .destructive) {
                    do { try LabelStore.delete(label, in: context) }
                    catch { errorMessage = LabelStore.message(for: error) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Your codes will be kept. Codes with no remaining labels will appear in History.")
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
    }
}

// MARK: - ManagedLabelRow

private struct ManagedLabelRow: View {
    let label: CodeLabel
    let onEdit: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack {
            CodeLabelBadge(label: label)
            Spacer()
            Text(label.records.count, format: .number).foregroundStyle(.secondary)
            if label.isBookmark {
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
                    .accessibilityLabel("System Label")
            } else {
                Menu {
                    Button("Edit Label", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: { Image(systemName: "ellipsis.circle").padding(8) }
                .accessibilityLabel("Label Options")
            }
        }
    }
}

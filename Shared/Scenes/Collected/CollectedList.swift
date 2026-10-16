import SwiftData
import SwiftUI

// MARK: - CollectedList

struct CollectedList: View {
    @Query(sort: \CodeLabel.creationDate) private var labels: [CodeLabel]
    @State private var selectedLabelID: UUID?
    @State private var isManagingLabels = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            LabeledRecordsView(labelID: selectedLabelID)
                                .frame(minHeight: geometry.size.height, alignment: .top)
                        } header: {
                            LabelFilterBar(labels: labels, selection: $selectedLabelID)
                                .padding(.top, 16)
                                .accessibilityIdentifier("labelFilterBar")
                        }
                    }
                }
                .accessibilityIdentifier("collectedScrollView")
                .scrollEdgeEffectStyle(.soft, for: .all)
            }
            .background { FlowingGradientBackground(palette: .collected) }
            .navigationTitle(.collected)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isManagingLabels = true } label: {
                        Label("Manage Labels", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $isManagingLabels) { LabelManagementView() }
            .onChange(of: labels.map(\.id)) { _, ids in
                if let selectedLabelID, !ids.contains(selectedLabelID) { self.selectedLabelID = nil }
            }
        }
    }
}

// MARK: - LabelFilterBar

private struct LabelFilterBar: View {
    let labels: [CodeLabel]
    @Binding var selection: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { selection = nil } label: { Text("All") }
                    .tint(selection == nil ? .accentColor : .secondary)
                    .accessibilityAddTraits(selection == nil ? .isSelected : [])
                    .buttonStyle(LabelFilterButtonStyle(isSelected: selection == nil))
                ForEach(labels) { label in
                    Button { selection = label.id } label: {
                        Label {
                            if label.title != nil { CodeLabelTitle(label: label) }
                        } icon: { Image(systemName: label.displaySymbolName) }
                    }
                    .buttonStyle(LabelFilterButtonStyle(isSelected: selection == label.id))
                    .tint(selection == label.id ? .accentColor : .secondary)
                    .accessibilityLabel(CodeLabelTitle(label: label).text)
                    .accessibilityAddTraits(selection == label.id ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - LabelFilterButtonStyle

/// A glass button style that emphasizes the selected label filter.
private struct LabelFilterButtonStyle: PrimitiveButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        if isSelected {
            Button(configuration)
                .buttonStyle(.glassProminent)
        } else {
            Button(configuration)
                .buttonStyle(.glass)
        }
    }
}

// MARK: - LabeledRecordsView

private struct LabeledRecordsView: View {
    @Query private var records: [CodeRecord]

    init(labelID: UUID?) {
        let predicate: Predicate<CodeRecord>
        if let labelID {
            predicate = #Predicate { $0.labels.contains { $0.id == labelID } }
        } else {
            predicate = #Predicate { !$0.labels.isEmpty }
        }
        _records = Query(filter: predicate, sort: \CodeRecord.scannedAt, order: .reverse)
    }

    var body: some View {
        GlassEffectContainer {
            if records.isEmpty {
                EmptyStateView(title: "No Labeled Codes", message: "Add labels to a code from its details or History.")
                    .containerRelativeFrame(.vertical)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(records) { record in
                        RecordListItem(record: record)
                    }
                }
                .padding()
            }
        }
    }
}

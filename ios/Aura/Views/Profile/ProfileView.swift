import SwiftUI
import SwiftData

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    let entries: [HealthEntry]
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    callSettingsCard
                    privacyCard
                    statsCard
                    doctorVisitCard
                    demoCard
                    aiSummaryCard
                    aboutCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $viewModel.showSummarySheet) {
            HealthSummarySheet(summary: viewModel.healthSummary)
        }
        .sheet(isPresented: $viewModel.showSOAPSheet) {
            if let note = viewModel.soapNote {
                SOAPReportView(note: note)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(.purple)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Aura")
                    .font(.title2).fontWeight(.bold).foregroundStyle(.primary)
                Text("AI Health Diary")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Call Settings

    private var callSettingsCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Daily Call Settings", systemImage: "phone.fill")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)

                Text("Aura will call you daily at your chosen time to check in on your health.")
                    .font(.caption).foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    HStack {
                        Text("Name")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        TextField("Your name", text: $viewModel.userName)
                            .font(.subheadline)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                    }

                    HStack {
                        Text("Phone")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        TextField("+1XXXXXXXXXX", text: $viewModel.userPhone)
                            .font(.subheadline)
                            .keyboardType(.phonePad)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                    }

                    HStack {
                        Text("Time")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        DatePicker(
                            "",
                            selection: $viewModel.preferredCallTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }

                Button {
                    Task { await viewModel.saveCallSettings() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSavingProfile {
                            ProgressView().scaleEffect(0.8)
                        } else if viewModel.profileSaved {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                        Text(viewModel.profileSaved ? "Saved!" : viewModel.isSavingProfile ? "Saving…" : "Save Settings")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(viewModel.profileSaved ? Color.green : Color.purple)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(
                        viewModel.profileSaved
                            ? Color.green.opacity(0.08)
                            : Color.purple.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .disabled(viewModel.isSavingProfile || viewModel.userPhone.isEmpty)
            }
        }
    }

    // MARK: - Privacy

    private var privacyCard: some View {
        sectionCard {
            HStack(alignment: .top) {
                Image(systemName: "lock.shield")
                    .font(.title3)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 3) {
                    Text("All data stored locally")
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                    Text("Your health data stays on your device. AI analysis uses encrypted Azure API calls. Medical references are sourced from FDA FAERS and NLM MedlinePlus.")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(2)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Stats", systemImage: "chart.bar")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                Divider()
                HStack {
                    statItem("\(entries.filter { !$0.isProcessing }.count)", "Entries")
                    Spacer()
                    statItem("\(uniqueDays)", "Days")
                    Spacer()
                    statItem(topType, "Top Type")
                }
            }
        }
    }

    // MARK: - Doctor Visit (SOAP)

    private var doctorVisitCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prepare for Doctor Visit")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                        Text("Generate a SOAP clinical note from your diary — the same format doctors use.")
                            .font(.caption).foregroundStyle(.secondary).lineSpacing(2)
                    }
                }

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 8))
                        Text("FDA FAERS").font(.caption2).fontWeight(.medium)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.green.opacity(0.08), in: Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 8))
                        Text("NLM MedlinePlus").font(.caption2).fontWeight(.medium)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.green.opacity(0.08), in: Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "doc.text").font(.system(size: 8))
                        Text("SOAP Format").font(.caption2).fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.blue.opacity(0.08), in: Capsule())
                }

                Button {
                    Task { await viewModel.generateSOAPNote(entries: entries) }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGeneratingSOAP {
                            ProgressView().scaleEffect(0.8)
                        }
                        Label(
                            viewModel.isGeneratingSOAP ? "Generating SOAP Note…" : "Generate Clinical Report",
                            systemImage: "stethoscope"
                        )
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(entries.isEmpty ? Color.secondary : Color.blue)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(
                        entries.isEmpty
                            ? Color(.tertiarySystemFill)
                            : Color.blue.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .disabled(entries.isEmpty || viewModel.isGeneratingSOAP)
            }
        }
    }

    // MARK: - Demo Data

    private var demoCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Demo Data", systemImage: "wand.and.stars")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                Text("Load 14 days of sample entries to explore Aura's features.")
                    .font(.caption).foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {
                        viewModel.loadDemoData(in: modelContext)
                    } label: {
                        Label("Load Demo Data", systemImage: "arrow.down.circle")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    if !entries.isEmpty {
                        Button(role: .destructive) {
                            viewModel.clearAllData(context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .padding(.vertical, 10).padding(.horizontal, 14)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI Summary

    private var aiSummaryCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("AI Health Summary", systemImage: "brain.head.profile")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                Text("Generate a personalized AI overview of your recent health patterns.")
                    .font(.caption).foregroundStyle(.secondary)

                Button {
                    Task { await viewModel.generateHealthSummary(entries: entries) }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGeneratingSummary {
                            ProgressView().scaleEffect(0.8)
                        }
                        Label(
                            viewModel.isGeneratingSummary ? "Generating…" : "Generate Summary",
                            systemImage: "sparkles"
                        )
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(entries.isEmpty ? Color.secondary : Color.purple)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(
                        entries.isEmpty
                            ? Color(.tertiarySystemFill)
                            : Color.purple.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .disabled(entries.isEmpty || viewModel.isGeneratingSummary)
            }
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("About", systemImage: "info.circle")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                Divider()
                Text("MIT Minds & Machines Healthcare Hackathon 2026")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(["SwiftUI", "Azure OpenAI", "FDA FAERS", "SwiftData"], id: \.self) { t in
                        Text(t)
                            .font(.caption2).fontWeight(.medium).foregroundStyle(.secondary)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    ForEach(["FDA FAERS", "NLM MedlinePlus", "SOAP Notes"], id: \.self) { t in
                        Text(t)
                            .font(.caption2).fontWeight(.medium).foregroundStyle(.secondary)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                }
                Text("Aura v1.0.0")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Reusable

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3).fontWeight(.bold).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var uniqueDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    private var topType: String {
        Dictionary(grouping: entries, by: { $0.entryType })
            .mapValues { $0.count }
            .max(by: { $0.value < $1.value })?.key.displayName ?? "—"
    }
}

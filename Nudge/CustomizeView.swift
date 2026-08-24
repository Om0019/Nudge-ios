import SwiftUI

/// Everything from the "should have customizability" ask lives here:
/// accent color, light/dark preference, and which Today-screen sections
/// show (and in what order) — the interactive, user-controlled UI layout.
struct CustomizeView: View {
    @EnvironmentObject private var store: NudgeStore
    @Environment(\.dismiss) private var dismiss
    @State private var customColor: Color = .orange

    var body: some View {
        NavigationStack {
            Form {
                Section("Accent color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(ThemeStore.presetHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if hex == store.accentColorHex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { store.setAccentColorHex(hex) }
                        }
                    }
                    .padding(.vertical, 6)

                    ColorPicker("Custom color", selection: $customColor, supportsOpacity: false)
                        .onChange(of: customColor) { _, newValue in
                            store.setAccentColorHex(newValue.toHex())
                        }
                }

                Section("Appearance") {
                    Picker("Appearance", selection: Binding(
                        get: { store.appearance },
                        set: { store.setAppearance($0) }
                    )) {
                        ForEach(ThemeStore.Appearance.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ForEach(store.sectionOrder, id: \.self) { section in
                        HStack {
                            Image(systemName: section.symbolName)
                                .foregroundStyle(store.accentColor)
                                .frame(width: 24)
                            Text(section.title)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { !store.hiddenSections.contains(section) },
                                set: { store.setSection(section, visible: $0) }
                            ))
                            .labelsHidden()
                        }
                    }
                    .onMove { source, destination in
                        store.moveSections(from: source, to: destination)
                    }
                } header: {
                    Text("Today screen sections")
                } footer: {
                    Text("Drag to reorder. Turn off anything you don't want to see — the app adapts to how you work, not the other way around.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

extension Color {
    /// Round-trips a picked `Color` back into the `"RRGGBB"` hex strings
    /// used throughout the shared model layer.
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#Preview {
    CustomizeView().environmentObject(NudgeStore())
}

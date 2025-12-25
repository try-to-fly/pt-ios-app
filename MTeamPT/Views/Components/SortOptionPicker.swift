import SwiftUI

/// 排序选项选择器
struct SortOptionPicker: View {
    @Binding var selectedOption: SortOption

    var body: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                    HapticManager.shared.impact(.light)
                }) {
                    Label(option.rawValue, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedOption.icon)
                    .font(.caption)
                Text(selectedOption.rawValue)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
        }
    }
}

#Preview {
    SortOptionPicker(selectedOption: .constant(.recommended))
}

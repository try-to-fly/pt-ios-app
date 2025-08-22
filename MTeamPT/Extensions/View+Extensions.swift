import SwiftUI
import Foundation

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func shimmer(when isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
    
    func glassBackground() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    func cardStyle() -> some View {
        background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                shimmerOverlay
                    .opacity(isLoading ? 1 : 0)
            )
            .onAppear {
                if isLoading {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
    
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemGray5),
                        Color(.systemGray6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(.degrees(70))
            .offset(x: phase * 300 - 150)
            .mask(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
            )
    }
}

extension Color {
    static let systemBackground = Color(.systemBackground)
    static let secondarySystemBackground = Color(.secondarySystemBackground)
    static let tertiarySystemBackground = Color(.tertiarySystemBackground)
    static let systemGroupedBackground = Color(.systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(.secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(.tertiarySystemGroupedBackground)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        } else {
            return String(self.prefix(length)) + "..."
        }
    }
}

extension Int {
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // 精确的相对时间显示
    func relativeTimeDisplay() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        // 刚刚（小于1分钟）
        if interval < 60 {
            return "刚刚"
        }
        
        // X分钟前（1分钟 - 1小时）
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        }
        
        // X小时前（1小时 - 24小时）
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        }
        
        // X天前（1天 - 7天）
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
        
        // X周前（1周 - 4周）
        if interval < 2592000 {
            let weeks = Int(interval / 604800)
            return "\(weeks)周前"
        }
        
        // X月前（1月 - 12月）
        if interval < 31536000 {
            let months = Int(interval / 2592000)
            return "\(months)月前"
        }
        
        // X年前
        let years = Int(interval / 31536000)
        return "\(years)年前"
    }
    
    // 根据时间间隔返回不同的颜色
    func relativeTimeColor() -> Color {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        // 小于1小时 - 绿色（新鲜）
        if interval < 3600 {
            return .green
        }
        // 小于1天 - 蓝色（较新）
        if interval < 86400 {
            return .blue
        }
        // 小于1周 - 默认颜色
        if interval < 604800 {
            return .primary
        }
        // 超过1周 - 灰色（较旧）
        return .secondary
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                action(UIDevice.current.orientation)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
import Foundation
import SwiftUI

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toasts: [ToastItem] = []
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            let toast = ToastItem(
                id: UUID(),
                message: message,
                type: type,
                duration: duration
            )
            
            withAnimation(.spring()) {
                self.toasts.append(toast)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss(toast.id)
            }
        }
    }
    
    func success(_ message: String) {
        show(message, type: .success)
    }
    
    func error(_ message: String) {
        show(message, type: .error)
    }
    
    func warning(_ message: String) {
        show(message, type: .warning)
    }
    
    func info(_ message: String) {
        show(message, type: .info)
    }
    
    func dismiss(_ id: UUID) {
        withAnimation(.spring()) {
            toasts.removeAll { $0.id == id }
        }
    }
    
    func dismissAll() {
        withAnimation(.spring()) {
            toasts.removeAll()
        }
    }
}

struct ToastItem: Identifiable, Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: TimeInterval
}

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
}

struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)
                .font(.system(size: 20))
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        ForEach(toastManager.toasts) { toast in
                            ToastView(toast: toast) {
                                toastManager.dismiss(toast.id)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                    .animation(.spring(), value: toastManager.toasts)
                    .padding(.bottom, 100)
                }
            )
    }
}

extension View {
    func toastManager() -> some View {
        self.modifier(ToastModifier())
    }
}
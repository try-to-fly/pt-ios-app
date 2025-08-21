import Foundation
import SwiftUI

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showError = false
    
    private init() {}
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else if let searchError = error as? SearchError {
                self.currentError = AppError.api(searchError.localizedDescription)
            } else {
                self.currentError = AppError.unknown(error.localizedDescription)
            }
            self.showError = true
        }
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

enum AppError: LocalizedError, Identifiable {
    case network(String)
    case api(String)
    case authentication
    case validation(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .network(let message), .api(let message), .validation(let message), .unknown(let message):
            return message
        case .authentication:
            return "authentication"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .network(let message):
            return "网络错误: \(message)"
        case .api(let message):
            return "API错误: \(message)"
        case .authentication:
            return "认证失败，请检查API密钥"
        case .validation(let message):
            return "验证错误: \(message)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
    
    var icon: String {
        switch self {
        case .network:
            return "wifi.exclamationmark"
        case .api:
            return "server.rack"
        case .authentication:
            return "key.slash"
        case .validation:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .network:
            return .orange
        case .api:
            return .red
        case .authentication:
            return .purple
        case .validation:
            return .yellow
        case .unknown:
            return .gray
        }
    }
}

struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(error.color)
            
            VStack(spacing: 8) {
                Text("出错了")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text("重试")
                            .fontWeight(.medium)
                            .frame(minWidth: 80)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Button(action: onDismiss) {
                    Text("确定")
                        .fontWeight(.medium)
                        .frame(minWidth: 80)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func errorAlert(
        error: Binding<AppError?>,
        isPresented: Binding<Bool>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            "错误",
            isPresented: isPresented,
            presenting: error.wrappedValue
        ) { _ in
            if let onRetry = onRetry {
                Button("重试", action: onRetry)
                Button("取消", role: .cancel) { }
            } else {
                Button("确定", role: .cancel) { }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
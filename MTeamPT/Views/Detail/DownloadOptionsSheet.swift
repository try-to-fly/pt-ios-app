import SwiftUI
import UIKit

struct DownloadOptionsSheet: View {
    let downloadURL: String
    let torrentName: String
    let isDownloading: Bool
    let downloadedFile: DownloadedTorrent?
    let onCopyLink: () -> Void
    let onOpenExternal: () -> Void
    let onDownloadTorrent: () -> Void
    let onOpenDownloadedFile: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false
    @State private var showDownloadSuccessToast = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 16) {
                        torrentInfoCard
                        
                        downloadLinkCard
                        
                        actionButtons
                        
                        tipsSection
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .overlay(
            toastView
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("下载选项")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("选择下载方式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var torrentInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("种子信息", systemImage: "doc.text")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(torrentName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var downloadLinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("下载链接", systemImage: "link")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(downloadURL)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let downloadedFile = downloadedFile {
                // 已下载完成的按钮
                downloadCompletedButton(downloadedFile)
            } else if isDownloading {
                // 正在下载的按钮
                downloadingButton
            } else {
                // 普通下载按钮
                downloadTorrentButton
            }
            
            // 原有的打开外部应用和复制链接按钮
            Button(action: {
                onOpenExternal()
                HapticManager.shared.notification(.success)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "safari")
                        .font(.body)
                    Text("在浏览器中打开")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .foregroundColor(.primary)
            }
            
            Button(action: {
                onCopyLink()
                showCopiedToast = true
                HapticManager.shared.notification(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCopiedToast = false
                }
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                    Text("复制下载链接")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .foregroundColor(.primary)
            }
        }
    }
    
    private var downloadTorrentButton: some View {
        Button(action: {
            onDownloadTorrent()
            HapticManager.shared.notification(.success)
        }) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.body)
                Text("下载种子文件")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundColor(.white)
        }
    }
    
    private var downloadingButton: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            Text("正在下载...")
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange)
        )
        .foregroundColor(.white)
    }
    
    private func downloadCompletedButton(_ downloadedFile: DownloadedTorrent) -> some View {
        VStack(spacing: 12) {
            // 下载成功提示
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("下载完成")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(downloadedFile.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            
            // 用其他应用打开按钮
            Button(action: {
                onOpenDownloadedFile()
                HapticManager.shared.notification(.success)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                    Text("用其他应用打开")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("使用提示", systemImage: "lightbulb")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "1.circle.fill", text: "点击\"下载种子文件\"将文件保存到本地")
                TipRow(icon: "2.circle.fill", text: "下载完成后可用其他应用打开种子文件")
                TipRow(icon: "3.circle.fill", text: "复制链接后可在其他下载工具中使用")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var toastView: some View {
        if showCopiedToast {
            VStack {
                Spacer()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("链接已复制到剪贴板")
                        .fontWeight(.medium)
                }
                .padding()
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showCopiedToast)
                .padding(.bottom, 50)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
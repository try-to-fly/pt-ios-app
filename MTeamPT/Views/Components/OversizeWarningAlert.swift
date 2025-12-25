import SwiftUI

/// 过大资源警告弹窗
struct OversizeWarningAlert: View {
    let torrent: Torrent
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 警告图标
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("文件较大提醒")
                .font(.headline)

            Text(torrent.oversizeWarningMessage ?? "该文件较大，确定要继续吗？")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 文件信息
            VStack(spacing: 8) {
                HStack {
                    Text("总大小")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(torrent.formattedSize)
                        .fontWeight(.medium)
                }

                if torrent.isTVShow {
                    HStack {
                        Text("文件数量")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(torrent.fileCount) 个")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("平均每集")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f GB", torrent.averageFileSizeGB))
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }

                HStack {
                    Text("分辨率")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(torrent.resolution.displayName)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )

            // 按钮
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                        )
                }
                .foregroundColor(.primary)

                Button(action: onConfirm) {
                    Text("仍然选择")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
        .shadow(radius: 20)
        .padding(.horizontal, 40)
    }
}

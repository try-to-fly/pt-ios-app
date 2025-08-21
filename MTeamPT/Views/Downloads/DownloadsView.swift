import SwiftUI

struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.downloads.isEmpty {
                    emptyStateView
                } else {
                    downloadList
                }
            }
            .navigationTitle("下载列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.clearAllDownloads()
                        } label: {
                            Label("清空列表", systemImage: "trash")
                        }
                        
                        Button {
                            viewModel.refreshDownloads()
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("确认删除", isPresented: $viewModel.showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                viewModel.confirmDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这个种子文件吗？")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无下载")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("下载的种子文件将显示在这里")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var downloadList: some View {
        List {
            ForEach(viewModel.downloads, id: \.id) { download in
                DownloadRowView(
                    download: download,
                    onTap: { download in
                        // 点击直接打开分享面板
                        viewModel.openSharePanel(for: download)
                    },
                    onShare: { download in
                        viewModel.openSharePanel(for: download)
                    },
                    onDelete: { download in
                        viewModel.requestDelete(download)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color(.systemGroupedBackground))
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGroupedBackground))
    }
}

struct DownloadRowView: View {
    let download: DownloadedTorrent
    let onTap: (DownloadedTorrent) -> Void
    let onShare: (DownloadedTorrent) -> Void
    let onDelete: (DownloadedTorrent) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 文件图标
                Image(systemName: "doc.badge.arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                // 文件信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.torrentName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(download.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(download.fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(download.formattedDownloadDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 分享图标
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .onTapGesture {
                onTap(download)
            }
            .contextMenu {
                Button {
                    onShare(download)
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    onDelete(download)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    DownloadsView()
}
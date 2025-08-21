import SwiftUI

struct TorrentDetailView: View {
    let torrent: Torrent
    @StateObject private var viewModel: TorrentDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    init(torrent: Torrent) {
        self.torrent = torrent
        self._viewModel = StateObject(wrappedValue: TorrentDetailViewModel(torrent: torrent))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    infoSection
                    
                    labelsSection
                    
                    statsSection
                    
                    downloadSection
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.toggleFavorite()
                        }) {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.isFavorite ? .red : .gray)
                        }
                        
                        Button(action: {
                            shareItems = [torrent.name, "大小: \(torrent.formattedSize)"]
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(torrent.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let smallDescr = torrent.smallDescr, !smallDescr.isEmpty {
                Text(smallDescr)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack(spacing: 20) {
                if let rating = torrent.imdbRating, !rating.isEmpty {
                    RatingBadge(type: "IMDB", rating: rating)
                }
                
                if let rating = torrent.doubanRating, !rating.isEmpty {
                    RatingBadge(type: "豆瓣", rating: rating)
                }
                
                Spacer()
                
                if torrent.hasDiscount {
                    DiscountBadge(discountType: torrent.discountType)
                        .scaleEffect(1.2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack(spacing: 12) {
            InfoRow(icon: "doc.circle", title: "文件大小", value: torrent.formattedSize)
            InfoRow(icon: "film", title: "视频编码", value: torrent.videoCodec)
            InfoRow(icon: "speaker.wave.2", title: "音频编码", value: torrent.audioCodec)
            InfoRow(icon: "folder", title: "文件数量", value: torrent.numfiles)
            
            if torrent.countries.count > 0 {
                InfoRow(icon: "globe", title: "国家/地区", value: torrent.countries.joined(separator: ", "))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.formattedLabels, id: \.0) { label, color in
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(color.opacity(0.15))
                            )
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(viewModel.formattedLabels, id: \.0) { label, color in
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(color.opacity(0.15))
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "arrow.up.circle.fill",
                value: torrent.status.seeders ?? "0",
                label: "种子",
                color: viewModel.seedersColor
            )
            
            StatCard(
                icon: "arrow.down.circle.fill",
                value: torrent.status.leechers ?? "0",
                label: "下载",
                color: .orange
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                value: torrent.status.timesCompleted ?? "0",
                label: "完成",
                color: .green
            )
            
            StatCard(
                icon: "eye.fill",
                value: torrent.status.views ?? "0",
                label: "浏览",
                color: .blue
            )
        }
    }
    
    private var downloadSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.getDownloadLink()
            }) {
                if viewModel.isLoadingDownload && !viewModel.isDownloading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("正在准备...")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                } else if viewModel.isDownloading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("正在下载...")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                } else {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title3)
                        Text("下载种子")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
            }
            .buttonStyle(Download3DButtonStyle())
            .disabled(viewModel.isLoadingDownload || viewModel.isDownloading)
            
            Text("点击后将下载种子文件并打开分享面板")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct RatingBadge: View {
    let type: String
    let rating: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text("\(type): \(rating)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.15))
        )
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct Download3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: .blue.opacity(0.5),
                            radius: configuration.isPressed ? 2 : 8,
                            x: 0,
                            y: configuration.isPressed ? 2 : 5
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
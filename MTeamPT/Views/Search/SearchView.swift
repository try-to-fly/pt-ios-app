import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showFilters = false
    @State private var selectedTorrent: Torrent?
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    searchHeader
                    
                    if viewModel.isLoading && viewModel.torrents.isEmpty {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyView
                    } else {
                        torrentList
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedTorrent) { torrent in
                TorrentDetailView(torrent: torrent)
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("M-Team PT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            SearchBarView(text: $viewModel.searchText, placeholder: viewModel.searchPlaceholder)
                .padding(.horizontal)
            
            CategorySelectorView(selectedCategory: $viewModel.selectedCategory)
        }
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("正在搜索...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(viewModel.searchText.isEmpty ? "输入关键词开始搜索" : "没有找到相关种子")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !viewModel.searchText.isEmpty {
                Text("试试其他关键词或分类")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var torrentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.torrents) { torrent in
                    TorrentCardView(torrent: torrent)
                        .onTapGesture {
                            selectedTorrent = torrent
                            HapticManager.shared.impact(.light)
                        }
                        .onAppear {
                            viewModel.torrentAppeared(torrent)
                        }
                }
                
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { 
                    text = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct CategorySelectorView: View {
    @Binding var selectedCategory: TorrentCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TorrentCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let category: TorrentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
                HapticManager.shared.impact(.light)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: category.iconName)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? 
                          LinearGradient(
                              colors: [.blue, .blue.opacity(0.8)],
                              startPoint: .leading,
                              endPoint: .trailing
                          ) : 
                          LinearGradient(
                              colors: [Color(.systemGray6)],
                              startPoint: .leading,
                              endPoint: .trailing
                          )
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
import SwiftUI
import UIKit

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showFilters = false
    @State private var selectedTorrent: Torrent?
    @FocusState private var isSearchBarFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    searchHeader
                    
                    if isSearchBarFocused && !viewModel.isLoading {
                        searchHistorySection
                            .transition(.opacity)
                    } else if viewModel.isLoading && viewModel.torrents.isEmpty {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyView
                    } else {
                        torrentList
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSearchBarFocused)
            .navigationBarHidden(true)
            .sheet(item: $selectedTorrent) { torrent in
                TorrentDetailView(torrent: torrent)
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
            // 过大警告弹窗
            .overlay(
                Group {
                    if viewModel.showOversizeWarning, let torrent = viewModel.oversizeWarningTorrent {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.cancelOversizeDownload()
                            }

                        OversizeWarningAlert(
                            torrent: torrent,
                            onConfirm: {
                                viewModel.confirmOversizeDownload()
                                selectedTorrent = torrent
                                HapticManager.shared.impact(.light)
                            },
                            onCancel: {
                                viewModel.cancelOversizeDownload()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showOversizeWarning)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                Text("Cat")
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

                // 排序选择器
                SortOptionPicker(selectedOption: $viewModel.sortOption)

                Button(action: { showFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            SearchBarView(
                text: $viewModel.searchText,
                placeholder: viewModel.searchPlaceholder,
                isFocused: $isSearchBarFocused,
                isLoading: viewModel.isLoading,
                onSearchSubmit: {
                    viewModel.performSearch()
                    isSearchBarFocused = false
                    HapticManager.shared.impact(.light)
                },
                onClear: {
                    viewModel.clearResults()
                }
            )
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
        List {
            ForEach(viewModel.sortedTorrents) { torrent in
                Button(action: {
                    viewModel.selectTorrent(torrent) { shouldOpen in
                        if shouldOpen {
                            selectedTorrent = torrent
                            HapticManager.shared.impact(.light)
                        }
                    }
                }) {
                    TorrentCardView(torrent: torrent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .onAppear {
                    viewModel.torrentAppeared(torrent)
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .refreshable {
            viewModel.refresh()
        }
    }
    
    private var searchHistorySection: some View {
        SearchHistoryView(
            histories: viewModel.searchHistories,
            onSelect: { history in
                isSearchBarFocused = false
                viewModel.selectSearchHistory(history)
                HapticManager.shared.impact(.medium)
            },
            onRemove: { history in
                viewModel.removeSearchHistory(history)
                HapticManager.shared.notification(.success)
            },
            onClearAll: {
                viewModel.clearSearchHistory()
                HapticManager.shared.notification(.warning)
            }
        )
    }
}

// 搜索历史视图（列表式布局）
struct SearchHistoryView: View {
    let histories: [SearchHistory]
    let onSelect: (SearchHistory) -> Void
    let onRemove: (SearchHistory) -> Void
    let onClearAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("最近搜索")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                if !histories.isEmpty {
                    Button(action: {
                        onClearAll()
                        HapticManager.shared.impact(.light)
                    }) {
                        Text("清空")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            if histories.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("暂无搜索记录")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 60)
            } else {
                // 历史记录列表
                List {
                    ForEach(histories.prefix(20)) { history in
                        HistoryRowView(history: history)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(history)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onRemove(history)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
            }
        }
        .background(Color(.systemGroupedBackground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 历史记录行视图
struct HistoryRowView: View {
    let history: SearchHistory

    private var tintColor: Color {
        switch history.category {
        case .movie: return .blue
        case .tvshow: return .purple
        case .all: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            Circle()
                .fill(tintColor.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: history.category.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(tintColor)
                )

            // 关键词和分类/时间
            VStack(alignment: .leading, spacing: 3) {
                Text(history.keyword)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(history.category.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("·")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(history.displayTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 箭头指示
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSearchSubmit: () -> Void
    let onClear: (() -> Void)?
    
    init(
        text: Binding<String>,
        placeholder: String,
        isFocused: FocusState<Bool>.Binding,
        isLoading: Bool = false,
        onSearchSubmit: @escaping () -> Void,
        onClear: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isFocused = isFocused
        self.isLoading = isLoading
        self.onSearchSubmit = onSearchSubmit
        self.onClear = onClear
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .focused(isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    onSearchSubmit()
                    isFocused.wrappedValue = false
                }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .frame(width: 18, height: 18)
            } else if !text.isEmpty {
                Button(action: { 
                    text = ""
                    isFocused.wrappedValue = false
                    onClear?()
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
                        .stroke(isFocused.wrappedValue ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
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

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
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    } else if viewModel.isLoading && viewModel.torrents.isEmpty {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyView
                    } else {
                        torrentList
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isSearchBarFocused)
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
            ForEach(viewModel.torrents) { torrent in
                Button(action: {
                    selectedTorrent = torrent
                    HapticManager.shared.impact(.light)
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
        ScrollView {
            SearchHistoryView(
                histories: viewModel.searchHistories,
                onSelect: { history in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // 先收起历史面板，再触发搜索，确保显示loading
                        isSearchBarFocused = false
                        viewModel.selectSearchHistory(history)
                    }
                    HapticManager.shared.impact(.medium)
                },
                onRemove: { history in
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.removeSearchHistory(history)
                    }
                    HapticManager.shared.notification(.success)
                },
                onClearAll: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.clearSearchHistory()
                    }
                    HapticManager.shared.notification(.warning)
                }
            )
            .padding(.horizontal)
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// 搜索历史视图（优化样式）
struct SearchHistoryView: View {
    let histories: [SearchHistory]
    let onSelect: (SearchHistory) -> Void
    let onRemove: (SearchHistory) -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("最近搜索")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !histories.isEmpty {
                    Button(action: {
                        onClearAll()
                        HapticManager.shared.impact(.light)
                    }) {
                        Text("清空")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if histories.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("暂无搜索记录")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    Text("你的搜索历史将显示在这里")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 历史记录标签网格
                let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(histories.prefix(20)) { history in
                            HistoryChip(
                                history: history,
                                onTap: { onSelect(history) },
                                onRemove: { onRemove(history) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(maxHeight: 420)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

// 标签样式的历史项
struct HistoryChip: View {
    let history: SearchHistory
    let onTap: () -> Void
    let onRemove: () -> Void
    @State private var showDelete = false
    
    private var tintColor: Color {
        switch history.category {
        case .movie: return .blue
        case .tvshow: return .purple
        case .all: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: history.category.iconName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(tintColor)
                    )
                
                Text(history.keyword)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                Group {
                    if showDelete {
                        HStack {
                            Spacer(minLength: 0)
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    onRemove()
                                    showDelete = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red.opacity(0.85))
                            }
                        }
                        .padding(.trailing, 6)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDelete.toggle()
            }
        }
    }
}

struct SearchHistoryRowView: View {
    let history: SearchHistory
    let onSelect: () -> Void
    let onRemove: () -> Void
    @State private var isPressed = false
    @State private var showDeleteButton = false
    
    var body: some View {
        HStack(spacing: 14) {
            // 分类图标容器
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                history.category == .movie ? Color.blue.opacity(0.1) : 
                                history.category == .tvshow ? Color.purple.opacity(0.1) : 
                                Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: history.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(
                        history.category == .movie ? .blue : 
                        history.category == .tvshow ? .purple : 
                        .gray
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(history.keyword)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Label(history.category.displayName, systemImage: "tag.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Label(history.displayTime, systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .labelStyle(.titleOnly)
            }
            
            Spacer()
            
            // 删除按钮
            if showDeleteButton {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        onRemove()
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.8))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            showDeleteButton ? Color.red.opacity(0.2) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onSelect()
                HapticManager.shared.impact(.light)
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDeleteButton.toggle()
            }
            HapticManager.shared.impact(.medium)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteButton)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
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

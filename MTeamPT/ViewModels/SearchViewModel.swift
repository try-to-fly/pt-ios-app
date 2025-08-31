import Foundation
import Combine
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: TorrentCategory = .all
    @Published var torrents: [Torrent] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMorePages = false
    @Published var searchHistories: [SearchHistory] = []
    
    private var currentPage = 1
    private let pageSize = 20
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    
    var isEmpty: Bool {
        !isLoading && torrents.isEmpty && !searchText.isEmpty
    }
    
    var searchPlaceholder: String {
        "搜索\(selectedCategory.displayName)..."
    }
    
    init() {
        setupSearchDebounce()
        loadSearchHistories()
    }
    
    private func setupSearchDebounce() {
        $selectedCategory
            .sink { [weak self] _ in
                if !(self?.searchText.isEmpty ?? true) {
                    self?.search()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch() {
        search()
        // 添加搜索历史
        if !searchText.isEmpty {
            cacheManager.addSearchHistory(searchText, category: selectedCategory)
            loadSearchHistories()
        }
    }
    
    func search() {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            clearResults()
            return
        }
        
        currentPage = 1
        isLoading = true
        errorMessage = nil
        
        let params = SearchParams(
            keyword: searchText,
            category: selectedCategory,
            pageNumber: currentPage,
            pageSize: pageSize
        )
        
        if let cached = cacheManager.getSearchResult(for: params) {
            self.torrents = cached.torrents
            self.hasMorePages = cached.hasMore
            self.isLoading = false
            return
        }
        
        searchTask = Task {
            do {
                let result = try await apiService.searchTorrents(params: params)
                
                if !Task.isCancelled {
                    self.torrents = result.torrents
                    self.hasMorePages = result.hasMore
                    cacheManager.cacheSearchResult(result, for: params)
                }
            } catch {
                if !Task.isCancelled {
                    self.handleError(error)
                }
            }
            
            self.isLoading = false
        }
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMorePages && !searchText.isEmpty else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        let params = SearchParams(
            keyword: searchText,
            category: selectedCategory,
            pageNumber: currentPage,
            pageSize: pageSize
        )
        
        Task {
            do {
                let result = try await apiService.searchTorrents(params: params)
                
                if !Task.isCancelled {
                    self.torrents.append(contentsOf: result.torrents)
                    self.hasMorePages = result.hasMore
                    cacheManager.cacheSearchResult(result, for: params)
                }
            } catch {
                self.currentPage -= 1
                self.handleError(error)
            }
            
            self.isLoadingMore = false
        }
    }
    
    func refresh() {
        cacheManager.clearCache()
        search()
    }
    
    func clearResults() {
        torrents = []
        currentPage = 1
        hasMorePages = false
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        if let searchError = error as? SearchError {
            errorMessage = searchError.localizedDescription
        } else {
            errorMessage = "发生未知错误，请重试"
        }
        showError = true
    }
    
    func torrentAppeared(_ torrent: Torrent) {
        guard let index = torrents.firstIndex(where: { $0.id == torrent.id }) else { return }
        
        if index >= torrents.count - 3 {
            loadMore()
        }
    }
    
    // MARK: - 搜索历史管理
    
    func loadSearchHistories() {
        searchHistories = cacheManager.getSearchHistories()
    }
    
    func selectSearchHistory(_ history: SearchHistory) {
        searchText = history.keyword
        selectedCategory = history.category
        // 清空当前结果以显示loading状态
        torrents = []
        search()
        // 更新选中的搜索历史时间戳
        cacheManager.addSearchHistory(history.keyword, category: history.category)
        loadSearchHistories()
    }
    
    func removeSearchHistory(_ history: SearchHistory) {
        cacheManager.removeSearchHistory(history)
        loadSearchHistories()
    }
    
    func clearSearchHistory() {
        cacheManager.clearSearchHistory()
        loadSearchHistories()
    }
}
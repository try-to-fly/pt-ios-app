import Foundation
import SwiftUI

class CacheManager {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private let memoryLimit = 50 * 1024 * 1024
    private let diskLimit = 200 * 1024 * 1024
    private let cacheLifetime: TimeInterval = 300
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = memoryLimit
        
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("MTeamPT", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        cleanExpiredCache()
    }
    
    func cacheSearchResult(_ result: SearchResult, for params: SearchParams) {
        let key = cacheKey(for: params)
        let entry = CacheEntry(data: result, timestamp: Date())
        cache.setObject(entry, forKey: key as NSString)
        
        saveToDisc(result, key: key)
    }
    
    func getSearchResult(for params: SearchParams) -> SearchResult? {
        let key = cacheKey(for: params)
        
        if let entry = cache.object(forKey: key as NSString) {
            if Date().timeIntervalSince(entry.timestamp) < cacheLifetime {
                return entry.data as? SearchResult
            } else {
                cache.removeObject(forKey: key as NSString)
            }
        }
        
        return loadFromDisk(key: key)
    }
    
    func cacheImage(_ data: Data, for url: String) {
        let key = url.hash.description
        let entry = CacheEntry(data: data, timestamp: Date())
        cache.setObject(entry, forKey: key as NSString, cost: data.count)
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).img")
        try? data.write(to: fileURL)
    }
    
    func getImage(for url: String) -> Data? {
        let key = url.hash.description
        
        if let entry = cache.object(forKey: key as NSString),
           let data = entry.data as? Data {
            return data
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).img")
        return try? Data(contentsOf: fileURL)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    private func cacheKey(for params: SearchParams) -> String {
        "\(params.keyword)_\(params.mode)_\(params.pageNumber)_\(params.pageSize)"
    }
    
    private func saveToDisc(_ result: SearchResult, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        if let encoded = try? JSONEncoder().encode(result.torrents) {
            try? encoded.write(to: fileURL)
        }
    }
    
    private func loadFromDisk(key: String) -> SearchResult? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard let data = try? Data(contentsOf: fileURL),
              let torrents = try? JSONDecoder().decode([Torrent].self, from: data) else {
            return nil
        }
        
        let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
        let modificationDate = attributes?[.modificationDate] as? Date ?? Date.distantPast
        
        if Date().timeIntervalSince(modificationDate) > cacheLifetime {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        return SearchResult(
            torrents: torrents,
            hasMore: false,
            totalCount: torrents.count,
            currentPage: 1,
            totalPages: 1
        )
    }
    
    private func cleanExpiredCache() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let expirationDate = Date().addingTimeInterval(-self.cacheLifetime)
            
            if let files = try? self.fileManager.contentsOfDirectory(
                at: self.cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) {
                for file in files {
                    if let attributes = try? self.fileManager.attributesOfItem(atPath: file.path),
                       let modificationDate = attributes[.modificationDate] as? Date,
                       modificationDate < expirationDate {
                        try? self.fileManager.removeItem(at: file)
                    }
                }
            }
            
            self.checkDiskUsage()
        }
    }
    
    private func checkDiskUsage() {
        var totalSize: Int64 = 0
        
        if let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
        }
        
        if totalSize > diskLimit {
            clearCache()
        }
    }
}

private class CacheEntry: NSObject {
    let data: Any
    let timestamp: Date
    
    init(data: Any, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}
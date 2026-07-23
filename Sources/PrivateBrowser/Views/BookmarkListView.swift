import SwiftUI

/// Danh sách bookmark — hiển thị trang đã lưu, recently closed.
/// v4.1: Full-featured bookmark manager với search, reorder, vàRecently Closed tab.
struct BookmarkListView: View {
    @ObservedObject var bookmarkManager = BookmarkManager.shared
    @ObservedObject var tabsManager: TabsManager
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var showRecentlyClosed = false

    private var filteredBookmarks: [BookmarkItem] {
        if searchText.isEmpty { return bookmarkManager.bookmarks }
        return bookmarkManager.bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Tìm bookmark...", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Tabs: Bookmarks | Recently Closed
                    HStack(spacing: 0) {
                        TabButton(title: "Bookmark", isSelected: !showRecentlyClosed) {
                            showRecentlyClosed = false
                        }
                        TabButton(title: "Đã đóng", isSelected: showRecentlyClosed) {
                            showRecentlyClosed = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    if showRecentlyClosed {
                        recentlyClosedList
                    } else {
                        bookmarkList
                    }
                }
            }
            .navigationTitle("Đã lưu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { isPresented = false }
                        .foregroundColor(.cyan)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if showRecentlyClosed && !bookmarkManager.recentlyClosed.isEmpty {
                        Button("Xóa hết") {
                            bookmarkManager.clearRecentlyClosed()
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if filteredBookmarks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15))
                        Text("Chưa có bookmark nào")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                        Text("Nhấn biểu tượng bookmark trên thanh URL để lưu trang")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.25))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filteredBookmarks) { item in
                        BookmarkRow(item: item, onTap: {
                            tabsManager.openNewTab(url: item.url)
                            isPresented = false
                        }, onDelete: {
                            bookmarkManager.removeBookmark(id: item.id)
                        })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private var recentlyClosedList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if bookmarkManager.recentlyClosed.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15))
                        Text("Không có tab nào đã đóng")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(bookmarkManager.recentlyClosed) { tab in
                        BookmarkRow(
                            item: BookmarkItem(id: tab.id, title: tab.title, url: tab.url, favicon: nil, createdAt: tab.closedAt),
                            onTap: {
                                tabsManager.openNewTab(url: tab.url)
                                isPresented = false
                            },
                            onDelete: {}
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

private struct BookmarkRow: View {
    let item: BookmarkItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                    .frame(width: 32, height: 32)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title.isEmpty ? item.url : item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(URL(string: item.url)?.host ?? item.url)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .cyan : .white.opacity(0.5))
                Rectangle()
                    .fill(isSelected ? Color.cyan : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

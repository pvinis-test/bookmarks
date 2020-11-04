//
//  ContentView.swift
//  Stuff
//
//  Created by Jason Barrie Morley on 28/10/2020.
//  Copyright © 2020 InSeven Limited. All rights reserved.
//

import Combine
import SwiftUI

enum BookmarksError: Error {
    case resizeFailure
}

extension UIImage {

    func resize(height: CGFloat) -> Future<UIImage, Error> {
        return Future { promise in
            DispatchQueue.global(qos: .background).async {
                let scale = height / self.size.height
                let width = self.size.width * scale
                UIGraphicsBeginImageContext(CGSize(width: width, height: height))
                defer { UIGraphicsEndImageContext() }
                self.draw(in:CGRect(x:0, y:0, width: width, height:height))
                guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                    promise(.failure(BookmarksError.resizeFailure))
                    return
                }
                promise(.success(image))
            }
        }

    }
}

struct BookmarkCell: View {

    var item: Item

    @Environment(\.manager) var manager: BookmarksManager
    @State var image: UIImage?
    @State var publisher: AnyCancellable?

    var title: String {
        if !item.title.isEmpty {
            return item.title
        } else if !item.url.lastPathComponent.isEmpty && item.url.lastPathComponent != "/" {
            return item.url.lastPathComponent
        } else if let host = item.url.host {
            return host
        } else {
            return "Unknown"
        }
    }

    var thumbnail: some View {
        ZStack {
            Text(title)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .clipped()
                    .background(Color.white)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            thumbnail
                .frame(height: 200)
                .clipped()
            VStack(alignment: .leading) {
                Text(title)
                    .lineLimit(1)
                Text(item.url.host ?? "Unknown")
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .onAppear {
            publisher = manager.thumbnailManager.thumbnail(for: item)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { (completion) in
                    if case .failure(let error) = completion {
                        print("Failed to download thumbnail with error \(error)")
                    }
                }, receiveValue: { image in
                    self.image = image
                })
        }
        .onDisappear {
            guard let publisher = publisher else {
                return
            }
            publisher.cancel()
        }
    }

}

extension String: Identifiable {
    public var id: String { self }
}

struct ContentView: View {

    enum SheetType {
        case settings
    }

    @Environment(\.manager) var manager: BookmarksManager
    @ObservedObject var store: Store
    @State var sheet: SheetType?
    @State var search = ""

    var items: [Item] {
        store.rawItems.filter {
            search.isEmpty ||
                $0.title.localizedStandardContains(search) ||
                $0.url.absoluteString.localizedStandardContains(search) ||
                $0.tags.contains(where: { $0.localizedStandardContains(search) } )
        }
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    Text("All Tags")
                }
                Group {
                    ForEach(store.tags) { tag in
                        Text(tag)
                    }
                }
            }
            .navigationTitle("Tags")
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                    ForEach(items) { item in
                        BookmarkCell(item: item)
                            .onTapGesture {
                                UIApplication.shared.open(item.url)
                            }
                            .contextMenu(ContextMenu(menuItems: {
                                Button("Share") {
                                    print("Share")
                                }
                            }))
                    }
                }
                .padding()
            }
            .navigationBarSearch($search)
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .settings:
                    NavigationView {
                        SettingsView(settings: manager.settings)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarItems(leading: Button(action: {
                sheet = .settings
            }) {
                Text("Settings")
                    .fontWeight(.regular)
            })
        }
    }

}

extension ContentView.SheetType: Identifiable {
    public var id: Self { self }
}
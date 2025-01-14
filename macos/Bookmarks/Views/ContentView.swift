// Copyright (c) 2020-2021 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import SwiftUI

import BookmarksCore
import Interact

struct ContentView: View {

    @Environment(\.manager) var manager: BookmarksManager
    @ObservedObject var store: Store
    @State var search = ""

    var items: [Item] {
        store.rawItems.filter {
            search.isEmpty ||
                $0.localizedSearchMatches(string: search)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(items) { item in
                        BookmarkCell(item: item)
                            .onTapGesture {
                                NSWorkspace.shared.open(item.url)
                            }
                            .contextMenu(ContextMenu(menuItems: {
                                Button("Open") {
                                    NSWorkspace.shared.open(item.url)
                                }
                                Divider()
                                Button("Share") {
                                    print("Share")
                                    print(item.identifier)
                                }
                            }))
                    }
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    manager.updater.start()
                } label: {
                    SwiftUI.Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem {
                SearchField(search: $search)
                    .frame(minWidth: 100, idealWidth: 300, maxWidth: .infinity)
            }
        }
        .frameAutosaveName("Main Window")
    }
}

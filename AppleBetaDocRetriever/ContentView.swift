//
//  ContentView.swift
//  AppleBetaDocRetriever
//
//  Created by Itsuki on 2026/04/04.
//

import SwiftUI

struct ContentView: View {
    @State private var retriever = BetaDocumentRetriever()
    @State private var viewed: [Document.ID] = []
    @Environment(\.openURL) private var openURL
    
    
    var body: some View {
        NavigationStack {
            List {
                OutlineGroup(retriever.betaDocuments, children: \.children) {
                    doc in
                    HStack(spacing: 12) {
                        let docViewed = self.viewed.contains(doc.id)
                        Text(doc.title)
                            .foregroundStyle(docViewed ? .secondary : .primary)
                            .font(doc.level == 0 ? .headline : .subheadline)
                            .fontWeight(.semibold)

                        if (doc.children?.count ?? 0) == 0 {
                            Text("Beta")
                                .foregroundStyle(.black)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4).fill(
                                        Color(
                                            red: 125 / 255,
                                            green: 255 / 255,
                                            blue: 228 / 255
                                        )
                                    )
                                )
                        }

                        Spacer()

                        if (doc.children?.count ?? 0) == 0,
                            let url = URL(
                                string: doc.path,
                                relativeTo: URL(string: retriever.rootURL)
                            )
                        {
                            Button(
                                action: {
                                    self.viewed.append(doc.id)
                                    openURL(url)
                                },
                                label: {
                                    Image(systemName: "safari")
                                        .padding(.all, 4)
                                        .contentShape(Rectangle())
                                }
                            )
                            #if os(macOS)
                                .buttonStyle(.plain)
                            #else
                                .buttonStyle(.borderless)
                            #endif
                        }
                    }
                    #if os(macOS)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    #endif
                }

                if let loadingMessage = retriever.loadingMessage {
                    ProgressView(label: {
                        Text(loadingMessage)
                    })
                    .controlSize(.extraLarge)
                    .padding(.vertical, 8)
                    #if os(macOS)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    #endif
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity, alignment: .center)

                }

            }
            .navigationTitle("Apple Beta Doc")
            .navigationSubtitle("New Frameworks & APIs")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(content: {
                if retriever.betaDocuments.isEmpty,
                    retriever.loadingMessage == nil
                {
                    ContentUnavailableView(
                        "No Beta Docs Retrieved",
                        systemImage: "document"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.gray.opacity(0.1))
                }
            })
            .toolbar(content: {
                #if os(macOS)
                    let placement: ToolbarItemPlacement = .confirmationAction
                #else
                    let placement: ToolbarItemPlacement = .topBarTrailing
                #endif

                ToolbarItem(
                    placement: placement,
                    content: {
                        if retriever.loadingMessage != nil {
                            Button(
                                action: {
                                    retriever.cancel()
                                },
                                label: {
                                    Text("Cancel")
                                }
                            )
                            .buttonStyle(.glassProminent)

                        } else {
                            Button(
                                action: {
                                    retriever.retrieve()
                                },
                                label: {
                                    Text("Start Retrieval")
                                }
                            )
                            .buttonStyle(.glassProminent)
                        }
                    }
                )
            })
            #if os(macOS)
                .frame(width: 480, height: 320)
                .fixedSize(horizontal: true, vertical: true)
            #endif

        }
    }
}

#Preview {
    ContentView()
}

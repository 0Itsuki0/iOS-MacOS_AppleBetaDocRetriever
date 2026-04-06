//
//  BetaDocumentRetriever.swift
//  AppleBetaDocRetriever
//
//  Created by Itsuki on 2026/04/06.
//


import SwiftUI
import WebKit

@Observable
class BetaDocumentRetriever {
    var retrievalLevel: Int = 0
    private(set) var loadingMessage: String? = nil
    private(set) var betaDocuments: [Document] = []
    private(set) var erroredDocuments: [Document] = []
    private(set) var error: Error?
    private var task: Task<Void, Error>?
    // cancel webpage during processing cause crashes
    private var shouldCancel: Bool = false

    let rootURL = "https://developer.apple.com"
    
    deinit {
        self.task?.cancel()
    }

    func cancel() {
        self.shouldCancel = true
        self.loadingMessage = nil
    }

    func retrieve() {
        self.betaDocuments = []
        self.erroredDocuments = []
        self.error = nil
        self.loadingMessage = "Loading Technologies..."
        self.task = Task {
            defer {
                self.loadingMessage = nil
            }
            var technologies: [Document] = []
            do {
                let result = try await self.retrieveDocuments(
                    "documentation",
                    level: 0
                )
                technologies = result.1
            } catch (let error) {
                print("Error retrieving technologies: \(error)")
                self.error = error
                return
            }

            for technology in technologies {
                guard !Task.isCancelled else {
                    return
                }
                // cancel Task while Webpage processing cause crashes.
                guard !self.shouldCancel else {
                    self.task?.cancel()
                    self.task = nil
                    return
                }
                do {
                    self.loadingMessage = "Checking \(technology.title)..."

                    let resolved = try await resolveTechnology(technology)
                    if resolved.beta || (resolved.children?.count ?? 0) > 0 {
                        self.betaDocuments.append(resolved)
                    }
                } catch (let error) {
                    print("Error resolving \(technology.title): \(error)")
                    self.erroredDocuments.append(technology)
                }
            }
        }
    }

    private func resolveTechnology(_ doc: Document) async throws -> Document {
        let (isBeta, children) = try await self.retrieveDocuments(
            doc.path,
            level: 1
        )
        let betaChildren = children.filter({ $0.beta })
        return Document(title: doc.title, path: doc.path, beta: isBeta, level: 0, children: (betaChildren.count > 0 && !isBeta) ? betaChildren : nil)
    }

    func retrieveDocuments(_ urlString: String, level: Int) async throws -> (
        Bool, [Document]
    ) {
        guard
            let url = URL(
                string: urlString,
                relativeTo: URL(string: self.rootURL)
            )
        else {
            throw RetrievalError.invalidURL
        }
        let webpage = self.createWebpage()
        webpage.load(url)
        try await waitForLoad(webpage)
        try await webpage.callJavaScript(
            """
            return new Promise(function (resolve, reject) {
                const wait = setInterval(function () {
                    const s = document.getElementById('sidebar-scroll-lock');
                    if (!s || !s.__vue__ || s.__vue__.items.length === 0) {
                        const btn = document.getElementById('nav-open-navigator');
                        if (btn) { btn.click(); }
                    } else {
                        clearInterval(wait);
                        clearTimeout(timeout);
                        resolve(true);
                    }
                }, 5);
                const timeout = setTimeout(function () {
                    clearInterval(wait);
                    reject('timeout');
                }, 10000);
            });
            """
        )

        guard
            let dictionary = try await webpage.callJavaScript(
                """
                const isBeta = !!document.querySelector('a.technology-title .badge-beta');  
                const s = document.getElementById('sidebar-scroll-lock');
                const items = s.__vue__.items.filter(function (i) {
                    return i.item != null && i.item.path != null && i.item.title != null;
                }).map(function (i) {
                    return { beta: i.item.beta ?? false, path: i.item.path, title: i.item.title, level: \(level) };
                });
                return { isBeta: isBeta, items: items }
                """
            ) as? [String: Any]
        else {
            throw RetrievalError.failToGetDoc
        }
        let isBeta = dictionary["isBeta"] as? Bool ?? false
        let array = dictionary["items"] as? [[String: Any]] ?? []
        let json = try JSONSerialization.data(withJSONObject: array)
        let decoder = JSONDecoder()
        let documents = try decoder.decode([Document].self, from: json)
        return (isBeta, documents)
    }

    func waitForLoad(_ webpage: WebPage) async throws {
        let maxEventAllowed: Int = 10
        var currentEvent: Int = 0
        for try await navigation in webpage.navigations {
            if navigation == .finished {
                return
            }
            currentEvent += 1
            if currentEvent > maxEventAllowed {
                throw RetrievalError.toManyRedirects
            }
        }
    }

    func createWebpage() -> WebPage {
        var configuration = WebPage.Configuration()
        var navigationPreferences = WebPage.NavigationPreferences()
        navigationPreferences.preferredContentMode = .desktop
        configuration.defaultNavigationPreferences = navigationPreferences

        return WebPage(configuration: configuration)
    }
}

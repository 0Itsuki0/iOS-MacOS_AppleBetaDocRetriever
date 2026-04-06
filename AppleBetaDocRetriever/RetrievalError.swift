//
//  RetrievalError.swift
//  AppleBetaDocRetriever
//
//  Created by Itsuki on 2026/04/06.
//

import Foundation

enum RetrievalError: Error {
    case failToGetDoc
    case invalidURL
    case toManyRedirects
}

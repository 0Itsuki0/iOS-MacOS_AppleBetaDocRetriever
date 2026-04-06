//
//  Document.swift
//  AppleBetaDocRetriever
//
//  Created by Itsuki on 2026/04/06.
//


import Foundation

struct Document: Identifiable, Codable {
    var title: String
    var path: String
    var beta: Bool
    var level: Int
    var children: [Document]? = nil

    var id: String {
        path
    }
}

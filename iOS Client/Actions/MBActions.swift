//
//  MBActions.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

struct NavigationActionSwitchTab: Action {
    var tab: Tab
}

struct PushRoute: Action {
    var route: Route
}

struct LoadedArticles: Action {
    var articles: Loaded<[MBArticle]>
}

struct SelectedArticle: Action {
    var article: MBArticle
}

struct PopCurrentNavigation: Action {
}

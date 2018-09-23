//
//  PodcastUninstaller.swift
//  iOS Client
//
//  Created by Jonathan Witten on 7/8/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import PromiseKit

protocol Uninstaller {
    func uninstall(podcastId: String) -> Promise<Bool>
    var delegate: UninstallerDelegate? { get set }
}

protocol UninstallerDelegate: class {
    func alertForUninstallItem(completion: @escaping ((UninstallApprovalStatus) -> Void))
}

class PodcastUninstaller: Uninstaller {
    
    let podcastStore: MBPodcastsStore
    let podcastPlayer: PodcastPlayer
    weak var delegate: UninstallerDelegate?
    
    init(store: MBPodcastsStore, player: PodcastPlayer) {
        self.podcastStore = store
        self.podcastPlayer = player
    }
    
    func uninstall(podcastId: String) -> Promise<Bool> {
        if podcastPlayer.currentlyPlayingPodcast?.title == podcastId {
            return Promise { fulfill, _ in
                delegate?.alertForUninstallItem {
                    _ = self.handleUninstallApprovalResponse(status: $0, title: podcastId).then { uninstalled in
                        fulfill(uninstalled)
                    }
                }
            }
        } else {
            return executeUninstall(title: podcastId)
        }
    }
    
    private func handleUninstallApprovalResponse(status: UninstallApprovalStatus, title: String) -> Promise<Bool> {
        switch status {
        case .approve:
            self.podcastPlayer.stop()
            return executeUninstall(title: title)
        case .deny:
            return Promise(value: false)
        }
    }
    
    private func executeUninstall(title: String) -> Promise<Bool> {
        return podcastStore.removePodcast(title: title).then {
            return Promise(value: true)
        }.recover { _ -> Promise<Bool> in
            return Promise(value: false)
        }
    }
}

enum UninstallApprovalStatus {
    case approve
    case deny
}

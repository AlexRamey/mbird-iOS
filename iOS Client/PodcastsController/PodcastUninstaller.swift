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
            return Promise { seal in
                delegate?.alertForUninstallItem {
                    _ = self.handleUninstallApprovalResponse(status: $0, title: podcastId).done { uninstalled in
                        seal.fulfill(uninstalled)
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
            return Promise { seal in
                seal.fulfill(false)
            }
        }
    }
    
    private func executeUninstall(title: String) -> Promise<Bool> {
        return Promise { seal in
            podcastStore.removePodcast(title: title)
            seal.fulfill(true)
        }
    }
}

enum UninstallApprovalStatus {
    case approve
    case deny
}

//
//  ImageMakerOperation.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/7/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class ImageMakerOperation: Operation {
    let article: MBArticle

    init(article: MBArticle) {
        self.article = article
    }
    
    override func main() {
        if self.isCancelled {
            return
        }
        
        guard let savedData = article.image?.image else {
            return
        }
        
        if self.isCancelled {
            return
        }
        
        let image = UIImage(data: savedData as Data)
        
        if self.isCancelled {
            return
        }
        
        article.uiimage = image
    }
}

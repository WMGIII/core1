//
//  SandBox.swift
//  core1
//
//  Created by WMIII on 2021/4/4.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import CoreData


struct SandBox {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ads.picUrl, ascending: true)],
        animation: .default)
    private var ads: FetchedResults<Ads>
    
    //保存图片至沙盒
    func saveImage(currentImage: UIImage, persent: CGFloat, imageName: String){
        if let imageData = currentImage.jpegData(compressionQuality: persent) as NSData? {
            let fullPath = NSHomeDirectory().appending("/Documents/").appending(imageName)
            imageData.write(toFile: fullPath, atomically: true)
            print("fullPath=\(fullPath)")
        }
    }
    
    
    func removefile(folderName: String){
        if folderName == ""{
            return
        }
        let fileManager = FileManager.default
        try! fileManager.removeItem(atPath: folderName)
    }
}

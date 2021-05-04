//
//  ContentView.swift
//  core1
//
//  Created by WMIII on 2021/4/3.
//

import SwiftUI
import UIKit
import Combine
import CoreData

class TimeHelp {
    var canceller: AnyCancellable?
        
    //每次都新建一个计时器
    func start(receiveValue: @escaping (() -> Void)) {
        let timerPublisher = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
        
        self.canceller = timerPublisher.sink { date in
            receiveValue()
        }
    }
    
    //暂停销毁计时器
    func stop() {
        canceller?.cancel()
        canceller = nil
    }
}


struct Advertisement: Codable {
    // var id = UUID()
    var picUrl: String
    var showTime: Int
    var timestamp: Int64
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ads.picUrl, ascending: true)],
        animation: .default)
    private var ads: FetchedResults<Ads>
    
    @State private var remoteImage :UIImage? = nil
    @State var isPresented = false
    let placeholderOne = UIImage(named: "Image1")
    
    let timer = Timer.publish(every: 1, on: .main, in: .common)
    
    @State private var second = 3
    private let timeHelper = TimeHelp()
    @State private var end = true

    var sand = SandBox()
    
    var body: some View {
        ZStack
        {
            Button("跳过 \(second)"){
                self.isPresented = true
            }
            .position(x: UIScreen.main.bounds.width - 45, y: 10.0)
            .onAppear()
            {
                for ad in ads {
                    print(ad.picUrl!)
                    print(ad.showTime)
                }
                
                guard self.end else {return}
                self.end = false
                self.second = 3
                self.timeHelper.start {
                    if self.second > 1 {
                        _ = self.second -= 1
                        
                    } else{
                        // 暂停
                        self.end = true
                        self.timeHelper.stop()
                        self.isPresented = true
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                print("消失")
            } content: {
                DetailView(message: "I'm missing you")
            }
            
            Image(uiImage: self.remoteImage ?? placeholderOne!)
            // Image(uiImage: self.placeholderOne!)
                .resizable()
                .scaledToFit()
                // .aspectRatio(contentMode: .fill)
                .onAppear(perform: fetchRemoteImg)
        }
    }
    
    func fetchRemoteImg()
    {
        getAdJson()
        if ads.count != 0
        {
            let timeStamp = Int(NSDate().timeIntervalSince1970)
            for index in 0...(ads.count - 1)
            {
                if ads[index].timestamp < timeStamp
                {
                    deleteItems(offsets: [index])
                    // print("删除了一个已过期活动")
                    break
                }
            }
            
            if ads.count == 0
            {
                return
            }
            
            let showad = ads[ads.count - 1]
            let fullPath = NSHomeDirectory().appending("/Documents/").appending(showad.picUrl!)
            if let savedImg = UIImage(contentsOfFile: fullPath)
            {
                remoteImage = savedImg
                
                ads[ads.count - 1].showTime -= 1
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                
                if ads[ads.count - 1].showTime == 0 {
                    deleteItems(offsets: [ads.count - 1])
                }
            }
            else
            {
                print("文件不存在")
            }
        }
        else
        {
            return
        }
    }
    
    
    func getAdJson()
    {
        // 测试用URL地址，本地Django服务器提供
        let urlAddress = "http://127.0.0.1:8000/api/getjson"
        
        guard let adurl = URL(string: urlAddress) else {return}
        URLSession.shared.dataTask(with: adurl) {
            (data, response, error) in
            do {
                if let d = data
                {
                    let jItem = try JSONDecoder().decode(Advertisement.self, from: d)
                    DispatchQueue.main.async {
                        addAd(adjson: jItem)
                    }
                }
                else
                {
                    print("no data.")
                }
            }
            catch
            {
                print("error")
            }
        }.resume()
    }

    
    func isAdExist(adname: String) -> Bool {
        for ad in ads {
            if adname == ad.picUrl
            {
                return true
            }
        }
        return false
    }
    
    
    private func addAd(adjson: Advertisement) {
        let arraySubStrings: [Substring] = adjson.picUrl.split(separator: "/")
        let arrayStrings: [String] = arraySubStrings.compactMap { "\($0)" }
        let length = arrayStrings.count
        
        if isAdExist(adname: arrayStrings[length - 1])
        {
            return
        }
        
        withAnimation {
            guard let url = URL(string: adjson.picUrl) else {return}
            URLSession.shared.dataTask(with: url)
            {
                (data, response, error) in
                if let img = UIImage(data: data!)
                {
                    let newAd = Ads(context: viewContext)
                    newAd.picUrl = arrayStrings[length - 1]
                    newAd.showTime = Int32(adjson.showTime)
                    newAd.timestamp = adjson.timestamp
                    
                    do {
                        sand.saveImage(currentImage: img, persent: 100, imageName: newAd.picUrl!)
                        try viewContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
                else
                {
                    print(error ?? "1")
                }
            }
            .resume()
        }
    }
    

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { ads[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct DetailView: View{
    let message: String
    
    var body: some View {
        VStack
        {
            Text(message)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

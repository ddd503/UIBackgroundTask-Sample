//
//  NotificationService.swift
//  UIBackgroundTaskNotification
//
//  Created by kawaharadai on 2018/08/05.
//  Copyright © 2018年 kawaharadai. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    /// 通知動作前に呼ばれる（iOS10以降専用、アプリがどんな状態でも呼ばれるが、フォアグラウンド時のみ通知表示は出ない）
    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        NSLog("onepiece didReceive\nrequest：%@", request.description)
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let imageUrl = request.content.userInfo["image-url"] as? String {
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task = session.dataTask(with: URL(string: imageUrl)!, completionHandler: { (data, response, error) in
                do {
                    if let writePath = NSURL(fileURLWithPath:NSTemporaryDirectory())
                        .appendingPathComponent("tmp.jpg") {
                        try data?.write(to: writePath)
                        
                        if let bestAttemptContent = self.bestAttemptContent {
                            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                            let attachment = try UNNotificationAttachment(identifier: "tiqav", url: writePath, options: nil)
                            bestAttemptContent.attachments = [attachment]
                            contentHandler(bestAttemptContent)
                        }
                    } else {
                        // error: writePath is not URL
                        if let bestAttemptContent = self.bestAttemptContent {
                            contentHandler(bestAttemptContent)
                        }
                    }
                } catch _ {
                    // error: data write error or create UNNotificationAttachment error
                    if let bestAttemptContent = self.bestAttemptContent {
                        contentHandler(bestAttemptContent)
                    }
                }
            })
            task.resume()
        } else {
            if let bestAttemptContent = self.bestAttemptContent {
                bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    /// 上記の通知準備には制限時間があり、時間切れ（30秒程度）の際はこのメソッドが呼ばれる
    /// とりあえずのcontentHandlerを返しておかないと通知実行自体が行われないため注意
    override func serviceExtensionTimeWillExpire() {
        NSLog("onepiece serviceExtensionTimeWillExpire\ntime out")
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}

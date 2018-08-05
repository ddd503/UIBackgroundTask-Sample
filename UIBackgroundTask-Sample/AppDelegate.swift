//
//  AppDelegate.swift
//  UIBackgroundTask-Sample
//
//  Created by kawaharadai on 2018/08/05.
//  Copyright © 2018年 kawaharadai. All rights reserved.
//

import UIKit
import UserNotifications
import AudioToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let appLaunchingSound: SystemSoundID = 1000
    private let didReceiveNotificationSound: SystemSoundID = 1005
    var window: UIWindow?
    var backgroundTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        if #available(iOS 10.0, *) {
            /// iOS10以上の通知作成
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            /// iOS9以前の通知作成（iOS9以前ではUNUserNotificationCenterが使えないためタスクキル時に）
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        /// 通知登録
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NSLog("onepiece didFinishLaunchingWithOptions")
        AudioServicesPlaySystemSound(appLaunchingSound)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
        //        self.backgroundTaskId = application.beginBackgroundTask(expirationHandler: {
        //            [weak self] in
        //            application.endBackgroundTask((self?.backgroundTaskId) ?? UIBackgroundTaskInvalid)
        //            self?.backgroundTaskId = UIBackgroundTaskInvalid
        //        })
    }
    
    /// 通知用デバイストークン登録後に走る（OSに関係なく）
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        // TODO: ここでサーバー側に宛先とするトークンを送信する
        print(token)
    }
    
    /// UIUserNotificationSettingsに登録時に動作（iOS9以前用、UserNotificationsを実装していないいる場合はiOS10以降ではここも呼ばれてしまう）
    /// フォアグラウンド時：通知表示なし（バナーを出すには独自の実装が必要）、通知受け取り時に走る
    /// バックグラウンド時：通知表示あり、通知受け取り時に走らない、通知タップ時に走る
    /// ※ ただしサーバー側でpayloadのcontent_availableキーの値がtrueならアプリをActive状態にするため呼べる
    /// タスクキル時：通知表示あり、通知受け取り時に走らない、通知タップ時に走らない（didFinishLaunchingWithOptionsまで動いて終わり）
    /// これはタスクキル時のタップで動かないため下を使う
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
    //    AudioServicesPlaySystemSound(didReceiveNotificationSound)
    //        print(userInfo)
    //    }
    
    /// UIUserNotificationSettingsに登録時に動作（iOS9以前用、UserNotificationsを実装していないいる場合はiOS10以降ではここも呼ばれてしまう）
    /// フォアグラウンド時：通知表示なし（バナーを出すには独自の実装が必要）、通知受け取り時に走る
    /// バックグラウンド時：通知表示あり、通知受け取り時に走らない、通知タップ時に走る
    /// ※ ただしサーバー側でpayloadのcontent_availableキーの値がtrueならアプリをActive状態にするため呼べる
    /// タスクキル時：通知表示あり、通知受け取り時に走らない、通知タップ時に走る
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        /// iOS10以降の場合はUserNotifications（AppExtention側で処理するので早期returnする）
        if #available(iOS 10.0, *) {
            completionHandler(.noData)
        } else {
            /// ここではiOS9以前の場合のみ通知を受け取る
            AudioServicesPlaySystemSound(didReceiveNotificationSound)
            NSLog("onepiece didReceiveRemoteNotification\nuserInfo：%@", userInfo.description)
            completionHandler(.newData)
        }
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// 以下、UNUserNotificationCenterに登録時に動作（iOS10以上用）
    
    @available(iOS 10.0, *)
    /// タップ時の挙動
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("onepiece didReceive response tap action")
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    /// フォアグラウンド時
    /// ※ UNNotificationServiceExtension側も呼ばれる（UNNotificationServiceExtensionで通知をカスタマイズして、ここで通知を出す）
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("onepiece willPresent notification\nnotification：%@", notification.description)
        completionHandler([.alert, .sound])
    }
    
}

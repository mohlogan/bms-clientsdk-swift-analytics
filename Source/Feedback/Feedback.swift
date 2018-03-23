/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import UIKit

public class Feedback{
    
    static var screenshot:UIImage?
    static var messages:[String] = [String]()
    static var instanceName:String?
    static var creationDate:String?
    internal static func topController(_ parent:UIViewController? = nil) -> UIViewController {
        if let vc = parent {
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return topController(selected)
            } else if let nav = vc as? UINavigationController, let top = nav.topViewController {
                return topController(top)
            } else if let presented = vc.presentedViewController {
                return topController(presented)
            } else {
                return vc
            }
        } else {
            return topController(UIApplication.shared.keyWindow!.rootViewController!)
        }
    }

    public static func invokeFeedback() -> Void {
        let uiViewController = topController(nil);
        Feedback.instanceName = NSStringFromClass(uiViewController.classForCoder)
        Feedback.creationDate = BMSLogger.dateFormatter.string(from: Date())
        Feedback.screenshot = takeScreenshot(uiViewController.view)
        
        let feedbackBundle = Bundle(for: UIImageControllerViewController.self)
        let feedbackStoryboard: UIStoryboard!
        feedbackStoryboard = UIStoryboard(name: "Feedback", bundle: feedbackBundle)
        let feedbackViewController : UIViewController = feedbackStoryboard.instantiateViewController(withIdentifier: "feedbackImageView") as! UIViewController
        uiViewController.present(feedbackViewController, animated: true, completion: nil)
    }
    
    public static func takeScreenshot(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public static func saveImage(_ image: UIImage) -> Void{
        if let data = UIImagePNGRepresentation(image) {
            var objcBool:ObjCBool = true
            let isExist = FileManager.default.fileExists(atPath: BMSLogger.feedbackDocumentPath, isDirectory: &objcBool)
            
            // If the folder with the given path doesn't exist already, create it
            if isExist == false{
                do{
                    try FileManager.default.createDirectory(atPath: BMSLogger.feedbackDocumentPath, withIntermediateDirectories: true, attributes: nil)
                }catch{
                    print("Something went wrong while creating a new folder")
                }
            }

            let filename = BMSLogger.feedbackDocumentPath+getInstanceName()+".png";
            FileManager.default.createFile(atPath: filename, contents: data, attributes: nil)
        }
    }
    
    internal static func getInstanceName() -> String {
        return Feedback.instanceName!+"_"+Feedback.creationDate!;
    }
    
    public static func send() -> Void {
        //TODO: Save Image - Done
        //TODO: Save other image related info in a json file - Done
        //TODO: Update summary json (AppFeedBackSummary.json)
        //TODO: Get the list of images need to send
        //TODO: iterate each
        //        - create zip and send
        //        - Add timeSent to feedback.json
        //        - Send th file
        //        - if Sucess Update summary json (AppFeedBackSummary.json)
    }
    
    struct sendEntry {
        var timeSent: String
        var sendArray: [String]
        init(timeSent:String, sendArray:[String]){
            self.timeSent = timeSent
            self.sendArray = sendArray
        }
    }
    
    struct AppFeedBackSummary {
        var saved: [String]
        var send: [sendEntry]
        
        init(json: [String: Any]){
            self.saved = json["saved"] as? [String] ?? [""]
            self.send = []
            let sendArray:[String: [String]] = json["send"] as! [String : [String]]
            for key in sendArray.keys {
                send.append(sendEntry(timeSent: key, sendArray: sendArray[key]!))
            }
        }
        
        var dictionaryRepresentation: [String: Any] {
            return [
                "saved" : saved,
                "send" : send
            ]
        }
    }
    
    internal static func getListOfFeedbackFilesToSend() -> [String] {
        let afbsFile = BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)
        
        do {
            let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
            var summary = AppFeedBackSummary(json: json as! [String : Any])
            return summary.saved
        }catch {}
        return [""]
    }
    
    internal static func updateSummaryJsonFile(_ entry: String, timesent:String, flag:Bool) -> Void {
        let afbsFile = BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)

        do {
            let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
            var summary = AppFeedBackSummary(json: json as! [String : Any])
            if flag == true {
                summary.saved.append(entry)
            }else {
                if summary.saved.contains(entry) == true {
                    //Remove from saved
                    for i in 0..<summary.saved.count {
                        if summary.saved[i].elementsEqual(entry) {
                            summary.saved.remove(at: i)
                            break
                        }
                    }
                    
                    //Add to send
                    for i in 0..<summary.send.count {
                        if summary.send[i].timeSent.elementsEqual(timesent) {
                            summary.send[i].sendArray.append(entry)
                            break
                        }
                    }
                }else {
                    return
                }
            }
            
            write(toFile: afbsFile, feedbackdata: convertToJSON(summary.dictionaryRepresentation)!)
        }catch{}
    }
    
    internal static func convertFileToString(filepath : String) -> String? {
        let fileURL = URL(string: filepath)
        var fileContent:String? = ""
        do {
            fileContent = try String(contentsOf: fileURL!, encoding: .utf8)
        }catch{}
        return fileContent
    }

    internal static func convertFileToData(filepath : String) -> Data? {
        let fileURL = URL(string: filepath)
        var fileContent:Data? = nil
        do {
            fileContent = try Data(contentsOf: fileURL!)
        }catch{}
        return fileContent
    }
    
    internal static func createFeedbackJsonFile() -> Void {
        let screenName = getInstanceName()
        let deviceID = BMSAnalytics.uniqueDeviceId
        let timeCreated  = Feedback.creationDate
        let id = deviceID! + "_" + screenName + "_" + timeCreated!

        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let sessionId = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId]
        let userID = BMSAnalytics.actualUserIdentity
        let jsonObject: [String: Any] = [
            "id": id,
            "comments": Feedback.messages,
            "screenName": screenName,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "sessionID": sessionId as Any,
            "username": userID as Any
        ]
        
        let filename = BMSLogger.feedbackDocumentPath+getInstanceName()+".json";
        let feedbackJsonString = convertToJSON(jsonObject)
        guard feedbackJsonString != nil else {
            let errorMessage = "Failed to write feedback json data to file. This is likely because the feedback data could not be parsed."
            print(errorMessage)
            return
        }
        write(toFile: filename, feedbackdata: feedbackJsonString!)
    }
    
    internal static func convertToJSON(_ feedbackData: [String: Any]?) -> String? {
        let logData: Data
        do {
            logData = try JSONSerialization.data(withJSONObject: feedbackData as Any, options: [])
        }
        catch {
            return nil
        }
        
        return String(data: logData, encoding: .utf8)
    }
    
    // Append log message to the end of the log file
    internal static func write(toFile file: String, feedbackdata : String) {
        
        if !BMSLogger.fileManager.fileExists(atPath: file) {
            BMSLogger.fileManager.createFile(atPath: file, contents: nil, attributes: nil)
        }
        
        let fileHandle = FileHandle(forWritingAtPath: file)
        let data = feedbackdata.data(using: .utf8)
        
        if fileHandle != nil && data != nil {
            fileHandle!.seekToEndOfFile()
            fileHandle!.write(data!)
            fileHandle!.closeFile()
        }
        else {
            let errorMessage = "Cannot write to file: \(file)."
            print(errorMessage)
        }
    }
}



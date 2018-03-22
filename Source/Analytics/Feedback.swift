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
    static var screenshot:UIImage?
    public static func invokeFeedback() -> Void {
        var uiViewController = topController(nil);
        var instanceName = NSStringFromClass(uiViewController.classForCoder)
        
        Feedback.screenshot = takeScreenshot(uiViewController.view)
        
        let feedbackBundle = Bundle(for: UIImageControllerViewController.self)
        var feedbackStoryboard: UIStoryboard!
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
    
    public static func saveImage(_ image: UIImage, filename: String) -> Void{
        if let data = UIImagePNGRepresentation(image) {
            let filename = getDocumentsDirectory().appendingPathComponent(filename)
            try? data.write(to: filename)
        }
    }
    
    public static func getDocumentsDirectory() -> URL {
        //TODO: Made sure we are returning BMSLogger.feedbackDocumentPath
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}



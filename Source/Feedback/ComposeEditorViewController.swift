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



// MARK: - Swift 3

#if swift(>=3.0)

import UIKit

class ComposeEditorViewController: UIViewController {
    
    var messages:[String] = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  messageBox.delegate = self as! UITextViewDelegate
        
        // Do any additional setup after loading the view.
        messageBox.placeholder = "Please enter your comments here"
        messageBox.textColor = UIColor.lightGray
    }
    
    
    @IBOutlet weak var messageBox: UITextView!
    
    @IBAction func messagePopupOK(_ sender: Any) {
        
        Feedback.messages.append(messageBox.text)
        
        //ViewController.messages.append(messageBox.text)
        
        //        createDir()
        //
        //        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //        let ourDir = docsDir.appendingPathComponent("ourCustomDir/")
        //        let tempDir = ourDir.appendingPathComponent("temp/")
        //        let unzippedDir = tempDir.appendingPathComponent("unzippedDir/")
        //        let unzippedfileDir = unzippedDir.appendingPathComponent("unZipped.txt")
        //        let zippedDir = tempDir.appendingPathComponent("Zipped.zip")
        //        do {
        //
        //            try messages.write(to: unzippedfileDir, atomically: false, encoding: .utf8)
        //
        //
        //            let x = SSZipArchive.createZipFile(atPath: zippedDir.path, withContentsOfDirectory: unzippedfileDir.path)
        //
        //            var zipData: NSData! = NSData()
        //
        //            do {
        //                zipData = try NSData(contentsOfFile: unzippedfileDir.path, options: NSData.ReadingOptions.mappedIfSafe)
        //                //once I get a readable .zip file, I will be using this zipData in a multipart webservice
        //            }
        //            catch let err as NSError {
        //                print("err 1 here is :\(err.localizedDescription)")
        //            }
        //        }
        //        catch let err as NSError {
        //
        //            print("err 3 here is :\(err.localizedDescription)")
        //        }
        
        
        
        
        //  let messageArray :String =
        
        //        let messageArray = messages
        //
        //        if let json = try? JSONSerialization.data(withJSONObject: messageArray, options: []) {
        //            if let content = String(data: json, encoding: .utf8) {
        //                print(content)
        //            }
        //        }
        dismiss(animated: false, completion: nil)
        
        
        
    }
    
    //    func createDir(){
    //        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //        let ourDir = docsDir.appendingPathComponent("ourCustomDir/")
    //        let tempDir = ourDir.appendingPathComponent("temp/")
    //        let unzippedDir = tempDir.appendingPathComponent("unzippedDir/")
    //        let fileManager = FileManager.default
    //        if fileManager.fileExists(atPath: tempDir.path) {
    //            deleteFile(path: tempDir)
    //            deleteFile(path: unzippedDir)
    //        } else {
    //            print("file does not exist")
    //            do {
    //                try FileManager.default.createDirectory(atPath: tempDir.path, withIntermediateDirectories: true, attributes: nil)
    //                try FileManager.default.createDirectory(atPath: unzippedDir.path, withIntermediateDirectories: true, attributes: nil)
    //                print("creating dir \(tempDir)")
    //            } catch let error as NSError {
    //                print("here : " + error.localizedDescription)
    //            }
    //        }
    //    }
    
    
}

extension UITextView :UITextViewDelegate
{
    
    /// Resize the placeholder when the UITextView bounds change
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }
    
    /// The UITextView placeholder text
    public var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }
    
    /// When the UITextView did change, show or hide the label based on if the UITextView is empty or not
    ///
    /// - Parameter textView: The UITextView that got updated
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.text.characters.count > 0
        }
    }
    
    /// Resize the placeholder UILabel to make sure it's in the same position as the UITextView text
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height
            
            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
    
    /// Adds a placeholder UILabel to this UITextView
    private func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()
        
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 100
        
        placeholderLabel.isHidden = self.text.characters.count > 0
        
        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
        self.delegate = self
    }
}

#endif

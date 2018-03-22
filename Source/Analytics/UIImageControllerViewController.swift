
import UIKit

class UIImageControllerViewController: UIViewController {
    
    var path = UIBezierPath()
    var startpoint = CGPoint()
    var touchpoint = CGPoint()
    static var touchEnabled:Bool = false
    static var isMarkerBtnPressed:Bool = false
    static var isComposeBtnPressed:Bool = false
    static var ext:UIImage?
    
    
    
    @IBOutlet weak var composeBtn: UIBarButtonItem!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var markerBtn: UIBarButtonItem!
    
    @IBOutlet weak var compBtn: UIBarButtonItem!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var imageViewGesture: UITapGestureRecognizer!
    
    @IBAction func editButtonTapped(_ sender: Any) {
        if editBtn.tintColor == UIColor.black {
            // UIImageControllerViewController.isMarkerBtnPressed = false
            imageView.isUserInteractionEnabled = true
            editBtn.tintColor = UIColor.orange
            UIImageControllerViewController.touchEnabled = true
            
        } else {
            editBtn.tintColor = UIColor.black
            UIImageControllerViewController.touchEnabled = false
        }
        
    }
    
    
    @IBAction func markerButtonTapped(_ sender: UIBarButtonItem) {
        if markerBtn.tintColor == UIColor.black {
            UIImageControllerViewController.isMarkerBtnPressed = true
            markerBtn.tintColor = UIColor.orange
            UIImageControllerViewController.touchEnabled = true
        } else {
            markerBtn.tintColor = UIColor.black
            UIImageControllerViewController.isMarkerBtnPressed = false
            UIImageControllerViewController.touchEnabled = false
        }
    }
    
    
    @IBAction func composeButtonTapped(_ sender: Any) {
        if UIImageControllerViewController.isComposeBtnPressed {
            UIImageControllerViewController.isComposeBtnPressed = false
        } else {
            UIImageControllerViewController.isComposeBtnPressed = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let vc = segue.destination as! ComposeEditorViewController
        vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext //All objects and view are transparent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isUserInteractionEnabled = false
        UIImageControllerViewController.touchEnabled = false
        // Do any additional setup after loading the view.
        imageView.clipsToBounds = true
        imageView.isMultipleTouchEnabled = false
        markerBtn.tintColor = UIColor.black
        
        //Tap Gesture Function
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(normalTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGesture)
        
        
        
    }
    
    @objc func normalTap(_ sender: UIGestureRecognizer){
        print("Normal tap")
        drawImageView(mainImage: #imageLiteral(resourceName: "edit-1"), withBadge:#imageLiteral(resourceName: "eraser") )
    }
    
    
    func drawImageView(mainImage: UIImage, withBadge badge: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(mainImage.size, false, 0.0)
        mainImage.draw(in: CGRect(x: 0, y: 0, width: mainImage.size.width, height: mainImage.size.height))
        badge.draw(in: CGRect(x: mainImage.size.width - badge.size.width, y: 0, width: badge.size.width, height: badge.size.height))
        
        let resultImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        imageView.image = Feedback.screenshot
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        if let point = touch?.location(in: imageView){
            startpoint = point
            
        }
        if (!UIImageControllerViewController.touchEnabled && UIImageControllerViewController.isComposeBtnPressed) {
            let image: UIImage = UIImage(named: "ios-checkmark")!
            let bgImage = UIImageView(image: image)
            bgImage.frame = CGRect(x: startpoint.x, y: startpoint.y, width: 20, height: 20)
            self.view.addSubview(bgImage) //check the image name
            performSegue(withIdentifier: "segueModal", sender: self)
            //  composeBtn.tintColor = UIColor.black
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (UIImageControllerViewController.touchEnabled) {
            let touch = touches.first
            if let point = touch?.location(in: imageView){
                touchpoint = point
                
            }
            path.move(to: startpoint)
            path.addLine(to: touchpoint)
            startpoint = touchpoint
            
            //call  draw
            draw()
        }
    }
    
    func draw(){
        let strokeLayer = CAShapeLayer()
        strokeLayer.fillColor = nil
        strokeLayer.lineWidth = 5
        strokeLayer.strokeColor = UIColor.yellow.cgColor
        if UIImageControllerViewController.isMarkerBtnPressed {
            strokeLayer.lineWidth = 15
            strokeLayer.strokeColor = UIColor.red.cgColor
        }
        strokeLayer.path = path.cgPath
        imageView.layer.addSublayer(strokeLayer)
        imageView.setNeedsDisplay()
        path = UIBezierPath()
    }
    
    @IBAction func composeFeedButton(_ sender: Any) {
        
        if (UIImageControllerViewController.isComposeBtnPressed ){
            UIImageControllerViewController.isComposeBtnPressed = false
            compBtn.tintColor = UIColor.black
            
        }else {
            UIImageControllerViewController.isComposeBtnPressed = true
            compBtn.tintColor = UIColor.orange
        }
    }
    
    
    /* To add an erase/undo button
     @IBAction func eraseButton(_ sender: UIBarButtonItem) {
     
     path.removeAllPoints()
     imageView.layer.sublayers = nil
     imageView.setNeedsDisplay()
     
     
     } */

    @IBAction func closeButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "Dismiss app Feedback?", message: "All data and comments made will be deleted, Do you want to continue?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Yes, Dismiss", style: UIAlertActionStyle.default, handler: {action in self.dismiss(animated: false, completion: nil)}))
        alert.addAction(UIAlertAction(title: "No, Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        
        // alert creation
        let alert = UIAlertController(title: "App feedback sent", message: "Thanks for the feedback, you make our app better!", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Ok, Got it", style: UIAlertActionStyle.default, handler: {action in self.dismiss(animated: false, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        Feedback.screenshot = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(Feedback.screenshot!, nil, nil, nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "feedbackImageView") as! UIViewController
        self.present(vc, animated: true, completion: nil)
    }
}

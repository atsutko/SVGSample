//
//  ViewController.swift
//  SVGSample
//
//  Created by TakaoAtsushi on 2018/07/03.
//  Copyright © 2018年 TakaoAtsushi. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var number: Int = 0

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
     super.viewDidLoad()
        
        webView.frame.size = CGSize(width: self.view.frame.width / 2, height: self.view.frame.height / 2)
        webView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        
        //パスを取得。これでプロジェクト内の特定ファイルのpathを取得。
        let path: String = Bundle.main.path(forResource: "apple", ofType: "svg")!
        print(path)
        
        //pathからurlを生成
        let url: URL = NSURL.fileURL(withPath: path)
        print(url)
        
        //特定のurlに対するリクエストを生成
        let request: URLRequest = URLRequest(url: url)
        
        //ロード
        self.webView.loadRequest(request)
 
        //タップを判定できるようにする。
        self.webView.isUserInteractionEnabled = true
       
        // パン（ドラッグ）の準備
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panGesture(gesture:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        self.webView.addGestureRecognizer(panGesture)
        
        // ピンチイン・アウトの準備
        let pinchGetsture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.pinchGesture(gesture:)))
        pinchGetsture.delegate = self
        self.webView.addGestureRecognizer(pinchGetsture)
        
        //ダブルタップを定義
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        
        //デリゲート先を自分に設定
        doubleTap.delegate = self
        
        //ダブルタップをwebViewに追加
        self.webView.addGestureRecognizer(doubleTap)
        
        
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    
    //Asks the delegate if two gesture recognizers should be allowed to recognize gestures simultaneously.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func panGesture(gesture: UIPanGestureRecognizer) {
        
        // 現在のtransfromを保存
        let transform = webView.transform
        
        // imageViewのtransformを初期値に戻す
        // これを入れないと、拡大時のドラッグの移動量が少なくなってしまう
        webView.transform = CGAffineTransform.identity
        
        // 画像をドラッグした量だけ動かす
        let point: CGPoint = gesture.translation(in: webView)
        let movedPoint = CGPoint(x: webView.center.x + point.x, y: webView.center.y + point.y)
        webView.center = movedPoint
        
        // 保存しておいたtransformに戻す
        webView.transform = transform
        
        // ドラッグで移動した距離をリセット
        gesture.setTranslation(CGPoint.zero, in: webView)
        
    }

    
    @objc func pinchGesture(gesture: UIPinchGestureRecognizer) {
        
        var currentTransform = webView.transform
        var pinchStartImageCenter = webView.center
        var pichCenter = CGPoint(x: 0, y: 0)

        
        if gesture.state == UIGestureRecognizerState.began {
            // ピンチジェスチャー・開始
            currentTransform = webView.transform
            
            // ピンチを開始したときの画像の中心点を保存しておく
            pinchStartImageCenter = webView.center
            
            let touchPoint1 = gesture.location(ofTouch: 0, in: self.webView)
            let touchPoint2 = gesture.location(ofTouch: 1, in: self.webView)
            
            // 指の中間点を求めて保存しておく
            // UIGestureRecognizerState.Changedで毎回求めた場合、ピンチ状態で片方の指だけ動かしたときに中心点がずれておかしな位置でズームされるため
             pichCenter = CGPoint(x: (touchPoint1.x + touchPoint2.x) / 2, y: (touchPoint1.y + touchPoint2.y) / 2)
            
        } else if gesture.state == UIGestureRecognizerState.changed {
            // ピンチジェスチャー・変更中
            let scale = gesture.scale // ピンチを開始してからの拡大率。差分ではない
            
            // ピンチした位置を中心としてズーム（イン/アウト）するように、画像の中心位置をずらす
            let newCenter = CGPoint(x: pinchStartImageCenter.x - ((pichCenter.x - pinchStartImageCenter.x) * scale - (pichCenter.x - pinchStartImageCenter.x)), y: pinchStartImageCenter.y - ((pichCenter.y - pinchStartImageCenter.y) * scale - (pichCenter.y - pinchStartImageCenter.y)))
            
            webView.center = newCenter
            
            webView.transform = currentTransform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
            
        } else if gesture.state == UIGestureRecognizerState.ended {
            // ピンチジェスチャー終了
            
            // 現在の拡大率を取得する
            let currentScale = sqrt(abs(webView.transform.a * webView.transform.d - webView.transform.b * webView.transform.c))
            
            // 初期サイズより小さい場合は、初期サイズに戻す
            if currentScale < 1.0 {
                UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {() -> Void in
                    self.webView.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
                    self.webView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    
                }, completion: {(finished: Bool) -> Void in
                })
            }
        }
    }
    
    
    @objc func doubleTap(gesture: UITapGestureRecognizer) {
        var currentTransform = webView.transform

        
        if gesture.state == UIGestureRecognizerState.ended {
            
            currentTransform = webView.transform
            var doubleTapStartCenter = webView.center
            
            var transform: CGAffineTransform! = nil
            var scale: CGFloat = 2.0 // ダブルタップでは現在のスケールの2倍にする
            
            // 現在の拡大率を取得する
            let currentScale = sqrt(abs(webView.transform.a * webView.transform.d - webView.transform.b * webView.transform.c))
            
            let tapPoint = gesture.location(in: webView)
            
            var newCenter: CGPoint
            
            // 拡大済みのサイズがmaxScaleを超えていた場合は、初期サイズに戻す
            if currentScale * scale > 5 {
                scale = 1
                transform = CGAffineTransform.identity
                newCenter = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
                doubleTapStartCenter = newCenter
                
            } else {
                transform = currentTransform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
                
                newCenter = CGPoint(x:
                    doubleTapStartCenter.x - ((tapPoint.x - doubleTapStartCenter.x) * scale - (tapPoint.x - doubleTapStartCenter.x)), y:
                    doubleTapStartCenter.y - ((tapPoint.y - doubleTapStartCenter.y) * scale - (tapPoint.y - doubleTapStartCenter.y)))
            }
            
            // ズーム（イン/アウト）と中心点の移動
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {() -> Void in
                self.webView.center = newCenter
                self.webView.transform = transform
                
            }, completion: {(finished: Bool) -> Void in
            })
            
        }
    }
    
}



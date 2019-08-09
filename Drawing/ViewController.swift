//
//  ViewController.swift
//  Drawing
//
//  Created by 海法修平 on 2019/08/08.
//  Copyright © 2019 shu26. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = .lightGray
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = 1.0
        
        //お絵かきの準備
        prepareDrawing()
    }

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canvasView: UIImageView!
    
    // 直前のタッチ座標の保存用
    var lastPoint: CGPoint?
    // 描画用の線の太さの保存用
    var lineWidth: CGFloat?
    // 描画色の保存用
    var drawColor = UIColor()
    // お絵かきに使用
    var bezierPath = UIBezierPath()
    // デフォルトの線の太さ
    let defaultLineWidth: CGFloat = 10.0
    
    // 拡大縮小
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.canvasView
    }
    
    // キャンバスの準備
    func prepareCanvas() {
        let canvasSize = CGSize(width: view.frame.width*2, height: view.frame.width*2)
        let canvasRect =  CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        var firstCanvasImage = UIImage()
        UIColor.white.setFill()
        UIRectFill(canvasRect)
        firstCanvasImage.draw(in: canvasRect)
        firstCanvasImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        canvasView.contentMode = .scaleAspectFit
        canvasView.image = firstCanvasImage
        UIGraphicsEndImageContext()
    }
    
    // UIGetureRecognizerでお絵かき対応．一本指でなぞった時のみと対応とする
    private func prepareDrawing() {
        // 実際のお絵かきで言う描く手段（色鉛筆？クレヨン？絵の具？など）の準備
        let myDraw = UIPanGestureRecognizer(target: self, action: #selector(self.drawGesture(_:)))
        myDraw.maximumNumberOfTouches = 1
        self.scrollView.addGestureRecognizer(myDraw)
        
        // 実際のお絵かきで言うかキャンパスの準備（何も書かれていないUIImageの作成）
        prepareCanvas()
    }
    
    // draw動作
    @objc func drawGesture(_ sender: Any) {
        guard let drawGesture = sender as? UIPanGestureRecognizer else {
            print("drawGesture Error happend.")
            return
        }
        
        guard let canvas = self.canvasView.image else {
            fatalError("self.pictureView.image not found")
        }
        
        // 描画用の線の太さを決定する
        lineWidth = defaultLineWidth
        // draw色を決定する
        drawColor = UIColor.black
        
        
        // タッチ座標を取得
        let touchPoint = drawGesture.location(in: canvasView)
        
        switch drawGesture.state {
        case .began:
            // タッチ座標をlastTouchPointとして保存する
            lastPoint = touchPoint
            
            // touchPointの座標はscrollView基準なのでキャンパスの大きさに合わせた座標に変換しなければいけない
            // LastPointをキャンパスサイズ基準にConvert
            let lastPointForCanvasSize = convertPointForCanvasSize(originalPoint: lastPoint!, canvasSize: canvas.size)
            // 描画の設定 端を丸くする
            bezierPath.lineCapStyle = .round
            // 描画線の太さ
            bezierPath.lineWidth = defaultLineWidth
            bezierPath.move(to: lastPointForCanvasSize)
        case .changed:
            // タッチポイントを最新として保存
            let newPoint = touchPoint
            // Draw実行
            let imageAfterDraw = drawGestureAtChanged(canvas: canvas, lastPoint: lastPoint!, newPoint: newPoint, bezierPath: bezierPath)
            // canvasに上書き
            self.canvasView.image = imageAfterDraw
            lastPoint = newPoint
            // Point保存
        case .ended:
            print("Finish dragging")
        default:
            ()
        }
    }
    
    // UIGestureRecognizerのStatusが，Changedの時に実行するDraw動作
    func drawGestureAtChanged(canvas: UIImage, lastPoint: CGPoint, newPoint: CGPoint, bezierPath: UIBezierPath) -> UIImage{
        // 最新のtouchPointとlastPointからmiddlePointを算出
        let middlePoint = CGPoint(x: (lastPoint.x + newPoint.x) / 2 , y: (lastPoint.y + newPoint.y) / 2)
        // 各ポイントの座標はscrollView基準なのでキャンパスの大きさに合わせた座標に変換しなければならない
        // 各ポイントをキャンパスサイズ基準にConvert
        let middlePointForCanvas = convertPointForCanvasSize(originalPoint: middlePoint, canvasSize: canvas.size)
        let lastPointForCanvas = convertPointForCanvasSize(originalPoint: lastPoint, canvasSize: canvas.size)
        
        // 曲線を描く
        bezierPath.addQuadCurve(to: middlePointForCanvas, controlPoint: lastPointForCanvas)
        // コンテキストを生成
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
        // コンテキストのRect
        let canvasRect = CGRect(x: 0, y: 0, width: canvas.size.width, height: canvas.size.height)
        // 既存のCanvasを準備
        self.canvasView.image?.draw(in: canvasRect)
        // drawをセット
        drawColor.setStroke()
        // drawを実行
        bezierPath.stroke()
        // draw後の画像
        let imageAfterDraw = UIGraphicsGetImageFromCurrentImageContext()
        // コンテキストを閉じる
        UIGraphicsEndImageContext()
        
        return imageAfterDraw!
        
        
    }
    
    /**
     (おまじない)座標をキャンバスのサイズに準じたものに変換する
     
     - parameter originalPoint : 座標
     - parameter canvasSize : キャンバスのサイズ
     - returns : キャンバス基準に変換した座標
     */
    func convertPointForCanvasSize(originalPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        
        let viewSize = scrollView.frame.size
        var ajustContextSize = canvasSize
        var diffSize: CGSize = CGSize(width: 0, height: 0)
        let viewRatio = viewSize.width / viewSize.height
        let contextRatio = canvasSize.width / canvasSize.height
        let isWidthLong = viewRatio < contextRatio ? true : false
        
        if isWidthLong {
            
            ajustContextSize.height = ajustContextSize.width * viewSize.height / viewSize.width
            diffSize.height = (ajustContextSize.height - canvasSize.height) / 2
            
        } else {
            
            ajustContextSize.width = ajustContextSize.height * viewSize.width / viewSize.height
            diffSize.width = (ajustContextSize.width - canvasSize.width) / 2
            
        }
        
        let convertPoint = CGPoint(x: originalPoint.x * ajustContextSize.width / viewSize.width - diffSize.width,
                                   y: originalPoint.y * ajustContextSize.height / viewSize.height - diffSize.height)
        
        
        return convertPoint
        
    }

}


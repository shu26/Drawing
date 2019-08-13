//
//  ViewController.swift
//  Drawing
//
//  Created by shuhei kaiho on 2019/08/08.
//  Copyright © 2019 shu26. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canvasView: UIImageView!
    
    var lastPoint: CGPoint?
    var lineWidth: CGFloat?
    var drawColor = UIColor()
    var bezierPath: UIBezierPath?
    let scale = CGFloat(30)
    var saveImageArray = [UIImage]()
    var currentDrawNumber = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = .lightGray
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = 1.0
        
        prepareDrawing()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.canvasView
    }
    
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
    
    private func prepareDrawing() {
        let myDraw = UIPanGestureRecognizer(target: self, action: #selector(self.drawGesture(_:)))
        myDraw.maximumNumberOfTouches = 1
        self.scrollView.addGestureRecognizer(myDraw)
        lineWidth = CGFloat(sliderValue.value) * scale
        drawColor = UIColor.black
        prepareCanvas()
        saveImageArray.append(self.canvasView.image!)
    }
    
    @objc func drawGesture(_ sender: Any) {
        guard let drawGesture = sender as? UIPanGestureRecognizer else {
            print("drawGesture Error happend.")
            return
        }
        guard let canvas = self.canvasView.image else {
            fatalError("self.pictureView.image not found")
        }
        let touchPoint = drawGesture.location(in: canvasView)
        
        switch drawGesture.state {
        case .began:
            bezierPath = UIBezierPath()
            guard let bzrPth  = bezierPath else {
                fatalError("bezierPath Error")
            }
            lastPoint = touchPoint
            let lastPointForCanvasSize = convertPointForCanvasSize(originalPoint: lastPoint!, canvasSize: canvas.size)
            bzrPth.lineCapStyle = .round
            bzrPth.lineWidth = lineWidth!
            bzrPth.move(to: lastPointForCanvasSize)
        case .changed:
            let newPoint = touchPoint
            guard let bzrPth = bezierPath else {
                fatalError("bezierPath Error")
            }
            let imageAfterDraw = drawGestureAtChanged(canvas: canvas, lastPoint: lastPoint!, newPoint: newPoint, bezierPath: bzrPth)
            self.canvasView.image = imageAfterDraw
            lastPoint = newPoint
        case .ended:
            while currentDrawNumber != saveImageArray.count-1 {
                saveImageArray.removeLast()
            }
            currentDrawNumber+=1
            saveImageArray.append(self.canvasView.image!)
            if currentDrawNumber != saveImageArray.count-1 {
                fatalError("index Error")
            }
        default:
            print("drawGesture state Error")
        }
    }
    
    func drawGestureAtChanged(canvas: UIImage, lastPoint: CGPoint, newPoint: CGPoint, bezierPath: UIBezierPath) -> UIImage{
        let middlePoint = CGPoint(x: (lastPoint.x + newPoint.x) / 2 , y: (lastPoint.y + newPoint.y) / 2)
        let middlePointForCanvas = convertPointForCanvasSize(originalPoint: middlePoint, canvasSize: canvas.size)
        let lastPointForCanvas = convertPointForCanvasSize(originalPoint: lastPoint, canvasSize: canvas.size)
        bezierPath.addQuadCurve(to: middlePointForCanvas, controlPoint: lastPointForCanvas)
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
        let canvasRect = CGRect(x: 0, y: 0, width: canvas.size.width, height: canvas.size.height)
        self.canvasView.image?.draw(in: canvasRect)
        drawColor.setStroke()
        bezierPath.stroke()
        let imageAfterDraw = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageAfterDraw!
    }
    
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
    
    @IBAction func selectRed(_ sender: Any) {
        drawColor = UIColor.red
    }
    @IBAction func selectGreen(_ sender: Any) {
        drawColor = UIColor.green
    }
    @IBAction func selectBlue(_ sender: Any) {
        drawColor = UIColor.blue
    }
    @IBAction func selectBlack(_ sender: Any) {
        drawColor = UIColor.black
    }
    
    @IBOutlet weak var sliderValue: UISlider!
    @IBAction func slideSlider(_ sender: Any) {
        lineWidth = CGFloat(sliderValue.value) * scale
    }
    
    @IBAction func pressUndoButton(_ sender: Any) {
        if currentDrawNumber <= 0 {
            return
        }
        self.canvasView.image = saveImageArray[currentDrawNumber - 1]
        currentDrawNumber-=1
    }
    @IBAction func pressRedoButton(_ sender: Any) {
        if currentDrawNumber + 1 > saveImageArray.count - 1 {
            return
        }
        self.canvasView.image = saveImageArray[currentDrawNumber + 1]
        currentDrawNumber+=1
    }
    @IBAction func pressSaveButton(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(self.canvasView.image!, self, nil, nil)
    }
}


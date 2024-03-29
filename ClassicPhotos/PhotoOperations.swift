/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit

enum PhotoRecordState {
    case new, downloaded, filtered, failed
}

class PhotoRecord: NSObject {
    let name: String
    let url: URL
    var state = PhotoRecordState.new
    var image = UIImage(named: "Placeholder")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

class PendingOperations {
    
    lazy var downloadInProgress: [IndexPath: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
    lazy var filterationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Filteration Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

class ImageDownloader: Operation {
    let photoRecord: PhotoRecord
    
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard let imageData = try? Data(contentsOf: photoRecord.url)
            else {
            return
        }
        
        if isCancelled {
            return
        }
        
        if !imageData.isEmpty {
            photoRecord.image = UIImage(data:imageData)
            photoRecord.state = .downloaded
        } else {
            photoRecord.state = .failed
            photoRecord.image = UIImage(named: "Failed")
        }
    }
}

class ImageFilteration: Operation {
    let photoRecord: PhotoRecord
    
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard self.photoRecord.state == .downloaded else {
            return
        }
        
        if let image = photoRecord.image, let sepiedImage = applySepiaFilter(image) {
            photoRecord.image = sepiedImage
            photoRecord.state = .filtered
        }
    }
    
    func applySepiaFilter(_ image: UIImage) -> UIImage? {
        
        guard let data = image.pngData() else {
            return nil
        }

        let inputImage = CIImage(data: data)
        
        if isCancelled {
            return nil
        }
        
        let context = CIContext(options: nil)
        
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        
        if isCancelled {
            return nil
        }
        
        guard let outputImage = filter.outputImage, let outImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outImage)
    }
}

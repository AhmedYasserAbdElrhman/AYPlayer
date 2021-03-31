//
//  AYPlayer.swift
//
//  Created by Ahmed Yasser on 3/31/21.
//

import Foundation
import AVFoundation

class AYPlayer: NSObject {
    
    enum Source {
        case local
        case stream
    }
    
    
    // MARK:- Public
    public var duration: Float {
        switch source {
        case .local:
            return Float(audioPlayer.duration)
        case .stream:
            let duration = streamPlayer?.currentItem?.asset.duration ?? CMTime(value: 0, timescale: 1)
            return Float(CMTimeGetSeconds(duration))
        }
    }
    
    public var currentTime: Float {
        switch source {
        case .local:
            return Float(audioPlayer.currentTime)
        case .stream:
            return _currentTime
        }
        
    }
    
    // MARK:- Variables
    private var url: URL
    private var audioPlayer = AVAudioPlayer()
    private var streamPlayer: AVPlayer?
    private var source: Source = .local
    private var _currentTime: Float = 0
    // MARK:- Init
    convenience override init() {
        self.init(url: URL(string: "")!)
    }
     init(url: URL) {
        self.url = url
        super.init()
        // Check if the url is Streamable
        let asset = AVAsset(url: url)
        if asset.isPlayable && asset.isReadable {
            // Go with stream
            prepareAVPlayer(url: url)
            self.source = .stream
        } else {
            // Go with download
            configureSession(url: url)
            self.source = .local
        }

    }
    
    
    // MARK:- Functions
    private func prepareAVPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        streamPlayer = AVPlayer(playerItem: playerItem)
        let duration = playerItem.asset.duration
        let seconds = CMTimeGetSeconds(duration)
        guard let intSeconds = seconds.toInt() else { return }
        let minuteString = String(format: "%02d", (intSeconds / 60))
        let secondString = String(format: "%02d", (intSeconds % 60))
        print("TOTAL TIMER: \(minuteString):\(secondString)")
        streamPlayer!.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
            if self.streamPlayer?.currentItem?.status == .readyToPlay {
                let time : Float64 = CMTimeGetSeconds(self.streamPlayer!.currentTime())
                self._currentTime = Float(time)
            }
        }

        
    }
    
    private func prepareAudioPlayer(data: Data) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.volume = 1
            let minuteString = String(format: "%02d", (Int(audioPlayer.duration) / 60))
            let secondString = String(format: "%02d", (Int(audioPlayer.duration) % 60))
            print("TOTAL TIMER: \(minuteString):\(secondString)")
        } catch {
            print(error)
        }

    }
    
    private func configureSession(url: URL) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        func downloadFileFromURL(url: URL){
            let request = URLRequest(url: url)
            session.downloadTask(with: request, completionHandler: { [weak self] (localURL, response, error) -> Void in
                guard let `self` = self else {return}
                if let localURL = localURL {
                    if let data = try? Data(contentsOf: localURL) {
                        self.prepareAudioPlayer(data: data)
                    }
                }
                
            }).resume()
        }
        downloadFileFromURL(url: url)
    }


    func seek(to: Float) {
        switch source {
        
        case .local:
            let time = audioPlayer.duration * Double(to)
            audioPlayer.currentTime = time
        case .stream:
            streamPlayer?.seek(to: CMTime(value: Int64(to), timescale: 1))
        }
    }
    
    
    func play() {
        switch source {
        
        case .local:
            audioPlayer.play()
        case .stream:
            guard let player = streamPlayer else { return }
            player.play()
        }
    }
}
extension AYPlayer: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       //Trust the certificate even if not valid
       let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)

       completionHandler(.useCredential, urlCredential)
    }
}
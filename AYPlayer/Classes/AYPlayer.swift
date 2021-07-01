//
//  AYPlayer.swift
//
//  Created by Ahmed Yasser on 3/31/21.
//

import Foundation
import AVFoundation

protocol AYPlayerDelegate: class {
    func currentTime(_ inSeconds: Float64,_ totalFormatted: String)
}

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
    private var audioPlayerIsReady = false
    private var audioPlayClosure: (() -> Void)?
    private var streamPlayer: AVPlayer?
    private var source: Source = .local
    private var _currentTime: Float = 0
    weak var delegate: AYPlayerDelegate?
    // MARK:- Init
    convenience override init() {
        self.init(url: URL(string: "")!)
    }
     init(url: URL) {
        self.url = url
        self.audioPlayerIsReady = false
        self.audioPlayClosure = nil
        super.init()
        // Check if the url is Streamable
        let asset = AVAsset(url: url)
        DispatchQueue.global(qos: .background).async {
            if asset.isPlayable && asset.isReadable {
                // Go with stream
                self.prepareAVPlayer(url: url)
                self.source = .stream
            } else {
                // Go with download
                self.configureSession(url: url)
                self.source = .local
            }
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
                guard let delegate = self.delegate else { return }
                delegate.currentTime(time, "\(minuteString):\(secondString)")
            }
        }

        
    }
    
    private func prepareAudioPlayer(data: Data) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.volume = 1
            audioPlayerIsReady = true
            let minuteString = String(format: "%02d", (Int(audioPlayer.duration) / 60))
            let secondString = String(format: "%02d", (Int(audioPlayer.duration) % 60))
            print("TOTAL TIMER: \(minuteString):\(secondString)")
            audioPlayClosure?()
            DispatchQueue.main.async {
                _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    guard self.audioPlayer.isPlaying else { timer.invalidate(); return }
                    guard let delegate = self.delegate else {return}
                    delegate.currentTime(Float64(self.currentTime), "\(minuteString):\(secondString)")
                }
            }

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
            if audioPlayerIsReady {
            audioPlayer.play()
            } else {
                audioPlayClosure = {[weak self] in
                    guard let `self` = self else { return }
                    self.audioPlayer.play()
                }
            }
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


// MARK:- Extensions
extension Double {
    // If you don't want your code crash on each overflow, use this function that operates on optionals
    // E.g.: Int(Double(Int.max) + 1) will crash:
    // fatal error: floating point value can not be converted to Int because it is greater than Int.max
    func toInt() -> Int? {
        if self > Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}
extension Float {
    func toInt() -> Int? {
        if self > Float(Int.min) && self < Float(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}


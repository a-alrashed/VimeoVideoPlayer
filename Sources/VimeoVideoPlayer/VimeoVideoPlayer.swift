//
//  VimeoVideoPlayer.swift
//  VimeoVideoPlayer
//
//  Created by Azzam R Alrashed on 18/02/2021.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit
import AVKit

public enum VimeoVideoPlayerState: String {
    case Unstarted = "-1"
    case Ended = "0"
    case Playing = "1"
    case Paused = "2"
    case Buffering = "3"
    case Queued = "4"
}

public protocol VimeoVideoPlayerDelegate: class {
    func playerReady(_ videoPlayer: VimeoVideoPlayer)
    func playerStateChanged(_ videoPlayer: VimeoVideoPlayer, playerState: VimeoVideoPlayerState)
}

// Make delegate methods optional by providing default implementations
public extension VimeoVideoPlayerDelegate {
    func playerReady(_ videoPlayer: VimeoVideoPlayer) {}
    func playerStateChanged(_ videoPlayer: VimeoVideoPlayer, playerState: VimeoVideoPlayerState) {}
}

public class VimeoVideoPlayer: UIView {
    
    typealias VimeoPlayer = AVPlayer
    
    private var vimeoPlayer: VimeoPlayer?
    
    /** Used to respond to player events */
    open weak var delegate: VimeoVideoPlayerDelegate?
    
    /** Used to set the video quality */
    open var quality: HCVimeoVideoQuality = .quality1080p
    
    open func buildVimeoVideoPlayer(with id: String) {
        fetchVideoURLFrom(with: id) { url in
            
            self.vimeoPlayer = AVPlayer(url: url)
            let playerController = AVPlayerViewController()
            
            playerController.player = self.vimeoPlayer
            
            playerController.view.frame = self.bounds
            
            self.addSubview(playerController.view)
            
            self.delegate?.playerReady(self)
            
            
            // add observer to get notified when the video Ends
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.vimeoPlayer!.currentItem)
            
            // add observer to get notified when the video rate changes to know if the video is Playing, or did get Paused
            self.vimeoPlayer!.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        }
    }
    
    // MARK: Player controls

    open func mute() {
        vimeoPlayer?.isMuted = true
    }

    open func unMute() {
        vimeoPlayer?.isMuted = false
    }

    open func play() {
        vimeoPlayer?.play()
        delegate?.playerStateChanged(self, playerState: .Playing)
    }

    open func pause() {
        vimeoPlayer?.pause()
        delegate?.playerStateChanged(self, playerState: .Paused)
    }


    open func seekTo(_ seconds: CMTimeValue) {
        let time = CMTime(value: seconds , timescale: 1)
        vimeoPlayer?.seek(to: time)
    }

    open func getDuration() -> Double {
        return vimeoPlayer?.currentItem?.duration.seconds ?? 0.0
    }

    open func getCurrentTime() -> Double {
        return vimeoPlayer?.currentTime().seconds ?? 0.0
    }
    
    private func fetchVideoURLFrom(with id: String, completionHandler: @escaping (URL) -> Void) {
        HCVimeoVideoExtractor.fetchVideoURLFrom(id: id, completion: { ( video:HCVimeoVideo?, error:Error?) -> Void in
            if let err = error { print("Error = \(err.localizedDescription)"); return }
            guard let vid = video else { print("Invalid video object"); return }
            
            if let videoURL = vid.videoURL[self.quality] {
                DispatchQueue.main.async {
                    completionHandler(videoURL)
                }
            }
        })
        
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        delegate?.playerStateChanged(self, playerState: .Ended)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate", let player = object as? VimeoPlayer {
            switch player.rate {
            case 0:
                delegate?.playerStateChanged(self, playerState: .Paused)
            case 1:
                delegate?.playerStateChanged(self, playerState: .Playing)
            default:
                break
            }
        }
    }
    
    
    
    
}

import UIKit

class DeezerPlayerViewController: UIViewController {
    
    @IBOutlet private weak var imageTrack: UIImageView!
    @IBOutlet private weak var titleTrack: UILabel!
    @IBOutlet private weak var albumTrack: UILabel!
    @IBOutlet private weak var artistTrack: UILabel!
    
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var previousButton: UIButton!
    
    @IBOutlet private weak var bufferSlider: UISlider!
    @IBOutlet private weak var playerSlider: UISlider!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var elapsedTimeLabel: UILabel!
    
    @IBOutlet private weak var shuffleButton: UIButton!
    @IBOutlet private weak var repeatButton: UIButton!


    private lazy var player: DZRPlayer? = {
        guard let deezerConnect = DeezerManager.sharedInstance.deezerConnect,
            var _player = DZRPlayer(connection: deezerConnect) else {
                return nil
        }
        _player.shouldUpdateNowPlayingInfo = true
        _player.delegate = self
        return _player
    }()
    
    private var playable: DZRPlayable?
    private var currentIndex: Int = 0
    private var isPlayerSliderEditing = false
    private var isConformToRandomAcces: Bool {
        guard let playable = playable, let iterator = playable.iterator() as? NSObject else {
            return false
        }
        return iterator.conforms(to: DZRPlayableRandomAccessIterator.self)
    }
    
    func configure(playable: DZRPlayable, currentIndex: Int = 0) {
        self.playable = playable
        self.currentIndex = currentIndex
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        startPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
        player?.stop()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        title = "Player"
        shuffleButton.isHidden = !isConformToRandomAcces
        repeatButton.isHidden = !isConformToRandomAcces
        setupSliders()
    }
    
    private func setupPlayPauseButton() {
        guard let player = player else {
            return
        }
        
        nextButton.isEnabled = player.isReady()
        previousButton.isEnabled = player.isReady()
        playPauseButton.setImage(player.isPlaying() ? #imageLiteral(resourceName: "Player_Pause_Normal") : #imageLiteral(resourceName: "Player_Play_Normal") , for: .normal)
        playPauseButton.setImage(player.isPlaying() ? #imageLiteral(resourceName: "Player_Pause_Highlighted") : #imageLiteral(resourceName: "Player_Play_Highlighted") , for: .highlighted)
    }
    
    private func clearUI() {
        artistTrack.text = ""
        albumTrack.text = ""
        titleTrack.text = ""
        imageTrack.image = nil
        clearElapseView()
    }
    
    private func setup(track: DZRTrack) {
        clearUI()
        
        DeezerManager.sharedInstance.getData(track: track) {[weak self] (data, error) in
            guard let data = data, let strongSelf = self else {
                if let error = error {
                    self?.present(error: error)
                }
                return
            }
            if let artist = data[DZRPlayableObjectInfoCreator] as? String {
                strongSelf.artistTrack.text = artist
            }
            
            if let album = data[DZRPlayableObjectInfoSource] as? String {
                strongSelf.albumTrack.text = album
            }
            
            if let title = data[DZRPlayableObjectInfoName] as? String {
                strongSelf.titleTrack.text = title
            }
            
        }
        
        DeezerManager.sharedInstance.getIllustration(track: track) {[weak self] (image, error) in
            guard let image = image, let strongSelf = self else {
                if let error = error {
                    self?.present(error: error)
                }
                return
            }
            
            strongSelf.imageTrack.image = image
        }
    }
    
    private func setupDuration(progress: Float) {
        guard let player = player, progress != -1 else {
            durationLabel.text = "--:--"
            elapsedTimeLabel.text = "--:--"
            return
        }
        
        let currentDuration = Float(player.currentTrackDuration)
        let currentDurationString = getTimeStringFromSeconds(seconds: UInt32(currentDuration * progress))
        let trackDurationString = getTimeStringFromSeconds(seconds: UInt32(player.currentTrackDuration))
        durationLabel.text = currentDurationString
        elapsedTimeLabel.text = trackDurationString
    }
    
    private func setupSliderValue(progress: Float) {
        playerSlider.value = progress
    }
    
    // MARK: - Utils
    
    private func getTimeStringFromSeconds(seconds : UInt32) -> String {
        let minutes = seconds / 60;
        let currentSeconds = seconds - (minutes * 60)
        if currentSeconds < 10 {
            return "\(minutes):0\(currentSeconds)"
        }
        return "\(minutes):\(currentSeconds)"
    }
    
    // MARK: - Actions
    
    @IBAction private func playPause() {
        guard let player = player else {
            return
        }
        
        player.isPlaying() ? player.pause() : player.play()
    }
    
    @IBAction private func next() {
        player?.next()
    }
    
    @IBAction private func previous() {
        player?.previous()
    }
    
    @IBAction private func shuffleMode() {
        guard let player = player else {
            return
        }
        
        player.toggleShuffleMode()
        let image = player.shuffleMode ? #imageLiteral(resourceName: "Player_Shuffle_Active") : #imageLiteral(resourceName: "Player_Shuffle")
        shuffleButton.setImage(image, for: .normal)
    }
    
    @IBAction private func repeatMode() {
        guard let player = player else {
            return
        }
	
        player.updateRepeatMode(DZRPlaybackRepeatMode(rawValue: (player.repeatMode.rawValue + 1) % 3)!)
        let image: UIImage
        switch player.repeatMode {
        case .allTracks:
            image = #imageLiteral(resourceName: "Player_Repeat_All_Active")
        case .currentTrack:
            image = #imageLiteral(resourceName: "Player_Repeat_One_Active")
        default:
            image = #imageLiteral(resourceName: "Player_Repeat")
        }
        repeatButton.setImage(image, for: .normal)
    }
    
    // MARK: - Remote Control
    
    override func remoteControlReceived(with event: UIEvent?) {
        if let event = event {
            switch event.subtype {
            case .remoteControlPlay:
                player?.play()
                
            case .remoteControlPause:
                player?.pause()
                
            case .remoteControlNextTrack:
                player?.next()
                
            case .remoteControlPreviousTrack:
                player?.previous()
                
            default: ()
            }
        }
    }
}

// MARK: - DZRPlayerDelegate

extension DeezerPlayerViewController: DZRPlayerDelegate {
    
    private func startPlayer() {
        guard let playable = playable, let player = player else {
            return
        }
        
        player.play(playable, at: currentIndex)
    }
    
    /**
     *   DZRPlayer pause was called
     **/
    
    func playerDidPause(_ player: DZRPlayer!) {
        setupPlayPauseButton()
    }
    
    /**
     *   DZRPlayer has encounter an error
     **/
    
    func player(_ player: DZRPlayer!, didEncounterError error: Error!) {
        print(error ?? "Error from player")
        clearUI()
        setupPlayPauseButton()
    }
    
    /**
     *   DZRPlayer has starting to play
     **/
    
    func player(_ player: DZRPlayer!, didStartPlaying track: DZRTrack!) {
        if track != nil {
            setup(track: track)
            setupPlayPauseButton()
        }
    }
    
    /**
     *   DZRPlayer is playing
     *
     *   Parameter playedBytes: The number of bytes already played
     *   Parameter totalyBytes: The total number of bytes to play for the current track
     **/
    
    func player(_ player: DZRPlayer!, didPlay playedBytes: Int64, outOf totalBytes: Int64) {
        if playedBytes == totalBytes {
            player?.next()
            return
        }
        
        if !isPlayerSliderEditing {
            var progress: Float = -1
            if totalBytes != 0 {
                progress = Float(playedBytes) / Float(totalBytes)
            }
            setupDuration(progress: progress)
            setupSliderValue(progress: progress)
        }
        setupPlayPauseButton()
    }
    
    /**
     *   DZRPlayer is buffering
     *
     *   Parameter bufferedBytes: The number of bytes buffered
     *   Parameter totalyBytes: The total number of bytes whose need to be buffered
     **/

    func player(_ player: DZRPlayer!, didBuffer bufferedBytes: Int64, outOf totalBytes: Int64) {
        let progress = Float(bufferedBytes) / Float(totalBytes)
       bufferSlider.value = progress
    }
}

// MARK: - Slider & Duration

extension DeezerPlayerViewController {
    
    private func setupSliders() {
        let transparentImage = #imageLiteral(resourceName: "transparentImage")
        
        let bufferMinimumTrackImage = #imageLiteral(resourceName: "Player_ProgressSlider_DownloadProgress").stretchableImage(withLeftCapWidth: 3, topCapHeight: 0)
        bufferSlider.setMinimumTrackImage(bufferMinimumTrackImage, for: .normal)
        let bufferMaximumTrackImage = #imageLiteral(resourceName: "Player_ProgressSlider_Background").stretchableImage(withLeftCapWidth: 3, topCapHeight: 0)
        bufferSlider.setMaximumTrackImage(bufferMaximumTrackImage, for: .normal)
        bufferSlider.setThumbImage(transparentImage, for: .normal)
        bufferSlider.isContinuous = false
        
        let playerMinimumTrackImage = #imageLiteral(resourceName: "Player_ProgressSlider_PlayProgress").stretchableImage(withLeftCapWidth: 3, topCapHeight: 0)
        playerSlider.setMinimumTrackImage(playerMinimumTrackImage, for: .normal)
        playerSlider.setMaximumTrackImage(transparentImage, for: .normal)
        playerSlider.isContinuous = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(gestureRecognizer:)))
        playerSlider.addGestureRecognizer(tapGestureRecognizer)
        playerSlider.addTarget(self, action: #selector(onSliderValueChanged(slider:event:)), for: .valueChanged)
    }
    
    @objc private func onSliderValueChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                isPlayerSliderEditing = true
            case .moved:
                setupDuration(progress: slider.value)
            case .ended:
                isPlayerSliderEditing = false
                guard let player = player else {
                    return
                }
                player.progress = Double(slider.value)
                player.play()
            default:
                break
            }
        }
    }

    @objc private func sliderTapped(gestureRecognizer: UIGestureRecognizer) {
        guard let player = player else {
            return
        }
        
        let pointTapped: CGPoint = gestureRecognizer.location(in: view)
        
        let positionOfSlider: CGPoint = playerSlider.frame.origin
        let widthOfSlider: CGFloat = playerSlider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(playerSlider.maximumValue) / widthOfSlider)
        
        playerSlider.setValue(Float(newValue), animated: true)
        
        player.progress = Double(playerSlider.value)
        player.play()
    }
    
    private func clearElapseView() {
        durationLabel.text = "--:--"
        elapsedTimeLabel.text = "--:--"
        bufferSlider.value = 0
        playerSlider.value = 0
    }
    
}

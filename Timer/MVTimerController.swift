import AVFoundation
import Cocoa

class MVTimerController: NSWindowController {
  private var mainView: MVMainView!
  private var clockView: MVClockView!

  private var audioPlayer: AVAudioPlayer? // player must be kept in memory
  private var soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")

  var isMainController: Bool = false

  convenience init() {
    let mainView = MVMainView(frame: NSRect.zero)

    let window = MVWindow(mainView: mainView)

    self.init(window: window)

    self.mainView = mainView
    self.mainView.controller = self
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)

    self.windowFrameAutosaveName = "TimerWindowAutosaveFrame"

    window.makeKeyAndOrderFront(self)

    loadViewStateFromUserDefaults()
  }

  convenience init(closeToWindow: NSWindow?) {
    self.init()

    if closeToWindow != nil {
      var point = closeToWindow!.frame.origin
      point.x += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      point.y += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      self.window?.setFrameOrigin(point)
    }
  }

  deinit {
    self.clockView.target = nil
    self.clockView.stop()
  }

  func showInDock(_ state: Bool) {
    self.clockView.inDock = state
    self.mainView.menuItem?.state = state ? .on : .off
  }

  func windowVisibilityChanged(_ visible: Bool) {
    clockView.windowIsVisible = visible
  }

  func playAlarmSound() {
    if soundURL != nil {
        audioPlayer = try? AVAudioPlayer(contentsOf: soundURL!)
        //audioPlayer?.volume = self.volume
        audioPlayer?.play()
    }
  }

  @objc func handleClockTimer(_ clockView: MVClockView) {
    let notification = NSUserNotification()
    notification.title = "It's time! 🕘"

    NSUserNotificationCenter.default.deliver(notification)

    NSApplication.shared.requestUserAttention(.criticalRequest)

    playAlarmSound()
  }

  override func keyUp(with theEvent: NSEvent) {
    self.clockView.keyUp(with: theEvent)
  }

  override func keyDown(with event: NSEvent) {
  }

  func pickSound(_ index: Int) {
    let sound: String?
    switch index {
    case -1:
        sound = nil

    case 0:
        sound = "alert-sound"

    case 1:
        sound = "alert-sound-2"

    case 2:
        sound = "alert-sound-3"

    default:
        sound = "alert-sound"
    }
    if sound != nil {
        self.soundURL = Bundle.main.url(forResource: sound, withExtension: "caf")

        // 'preview'
        playAlarmSound()
    } else {
        self.soundURL = nil
    }
  }

  func setViewState(_ value: Bool, forKey viewConfigKey: String) {
    setViewState(value, forKey: viewConfigKey, save: isMainController)
  }

  private func setViewState(_ value: Bool, forKey viewConfigKey: String, save: Bool) {
    let state: NSControl.StateValue = value ? .on : .off
    switch viewConfigKey {
    case MVUserDefaultsKeys.appearanceChangeOnFocusChange:
      mainView.appearanceChangeOnFocusMenuItem?.state = state
      clockView.appearanceChangeOnFocusChange(value)
    case MVUserDefaultsKeys.typicalTimeSuffixes:
      mainView.typicalTimeSuffixMenuItem?.state = state
      clockView.typicalSuffixes = value
    case MVUserDefaultsKeys.hideDigitalTimer:
      mainView.hideDigitalTimerMenuItem?.state = state
      clockView.timerTimeLabel.isHidden = value
    case MVUserDefaultsKeys.fullDiskTimer:
      mainView.fullDiskTimerMenuItem?.state = state
      clockView.showFullDiskTimer(value)

      // Hide digital timer when full disk view is on.
      // Doesn't look very good when both are enabled.
      // If full disk view is disabled, load whatever
      // default the user has set.
      let key = MVUserDefaultsKeys.hideDigitalTimer
      let hideDigitalTimer = value || UserDefaults.standard.bool(forKey: key)
      setViewState(hideDigitalTimer, forKey: key, save: false)
      mainView.hideDigitalTimerMenuItem?.isEnabled = !value
    default:
      break
    }
    if save {
      UserDefaults.standard.set(value, forKey: viewConfigKey)
    }
  }

  private func loadViewStateFromUserDefaults() {
    let keys: [String] = [
      MVUserDefaultsKeys.appearanceChangeOnFocusChange,
      MVUserDefaultsKeys.typicalTimeSuffixes,
      MVUserDefaultsKeys.hideDigitalTimer,
      MVUserDefaultsKeys.fullDiskTimer
    ]
    for key in keys {
      let value = UserDefaults.standard.bool(forKey: key)
      setViewState(value, forKey: key, save: false)
    }
  }
}

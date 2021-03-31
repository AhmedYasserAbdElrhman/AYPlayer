
## Simple Usage

```Swift
  var myPlayer: AYPlayer?
  override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = URL(string: "yourURL.mp3") else { return }
        myPlayer = AYPlayer(url: url)
  }
```

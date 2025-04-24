import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var updateTimer: Timer?
    var selectedCoin: (display: String, apiSymbol: String) = ("BTC", "BTCUSDT")
    var secondSelectedCoin: (display: String, apiSymbol: String) = ("ETH", "ETHUSDT")
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // NSStatusBar가 카메라 노치(섬) 영역을 자동 배려하여 배치합니다.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "\(selectedCoin.display): --  |  \(secondSelectedCoin.display): --"
        
        let menu = NSMenu()
        
        // 코인1 직접 입력 메뉴 항목 추가
        menu.addItem(withTitle: "코인1 직접 입력", action: #selector(promptCoin1), keyEquivalent: "")
        
        // 코인2 직접 입력 메뉴 항목 추가
        menu.addItem(withTitle: "코인2 직접 입력", action: #selector(promptCoin2), keyEquivalent: "")
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "종료", action: #selector(quitApp), keyEquivalent: "q")
        
        statusItem.menu = menu
        
        // 10초마다 가격 갱신하는 타이머 시작
        updateTimer = Timer.scheduledTimer(timeInterval: 10,
                                           target: self,
                                           selector: #selector(updatePrice),
                                           userInfo: nil,
                                           repeats: true)
        
        // 앱 시작 시 즉시 가격 업데이트
        updatePrice()
    }
    
    // 코인1 직접 입력
    @objc func promptCoin1() {
        let alert = NSAlert()
        alert.messageText = "코인1 기호 입력"
        alert.informativeText = "조회할 코인의 API 기호를 입력하세요 (예: BTCUSDT 또는 BTCKRW)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.stringValue = selectedCoin.apiSymbol
        alert.accessoryView = inputTextField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let inputSymbol = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !inputSymbol.isEmpty {
                selectedCoin = (display: inputSymbol, apiSymbol: inputSymbol)
                updatePrice()
            }
        }
    }
    
    // 코인2 직접 입력
    @objc func promptCoin2() {
        let alert = NSAlert()
        alert.messageText = "코인2 기호 입력"
        alert.informativeText = "조회할 코인의 API 기호를 입력하세요 (예: ETHUSDT 또는 ETHKRW)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.stringValue = secondSelectedCoin.apiSymbol
        alert.accessoryView = inputTextField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let inputSymbol = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !inputSymbol.isEmpty {
                secondSelectedCoin = (display: inputSymbol, apiSymbol: inputSymbol)
                updatePrice()
            }
        }
    }
    
    // 두 코인의 가격을 조회합니다.
    // 기호가 "KRW"로 끝나면 업비트 API를 사용하여 원화 가격을 조회합니다.
    // 그렇지 않으면 Binance API를 사용합니다.
    @objc func updatePrice() {
        let dispatchGroup = DispatchGroup()
        var firstPrice: Double?
        var firstChange: Double?
        var secondPrice: Double?
        var secondChange: Double?
        
        let coin1IsKRW = selectedCoin.apiSymbol.hasSuffix("KRW")
        let coin2IsKRW = secondSelectedCoin.apiSymbol.hasSuffix("KRW")
        
        // 코인1 가격 및 일일 변화율 요청
        dispatchGroup.enter()
        if coin1IsKRW {
            let coin = selectedCoin.apiSymbol.replacingOccurrences(of: "KRW", with: "")
            let market = "KRW-\(coin)"
            let urlString1 = "https://api.upbit.com/v1/ticker?markets=\(market)"
            if let url1 = URL(string: urlString1) {
                let task1 = URLSession.shared.dataTask(with: url1) { data, response, error in
                    if let data = data, error == nil,
                       let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let firstObject = jsonArray.first {
                        if let price = firstObject["trade_price"] as? Double {
                            firstPrice = price
                        }
                        if let changeRate = firstObject["signed_change_rate"] as? Double {
                            firstChange = changeRate * 100 // 백분율 변환
                        }
                    }
                    dispatchGroup.leave()
                }
                task1.resume()
            } else {
                dispatchGroup.leave()
            }
        } else {
            // Binance: 24hr 엔드포인트 (일일 변화율 포함)
            let urlString1 = "https://api.binance.com/api/v3/ticker/24hr?symbol=\(selectedCoin.apiSymbol)"
            if let url1 = URL(string: urlString1) {
                let task1 = URLSession.shared.dataTask(with: url1) { data, response, error in
                    if let data = data, error == nil,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let priceString = json["lastPrice"] as? String,
                           let price = Double(priceString) {
                            firstPrice = price
                        }
                        if let changePercentStr = json["priceChangePercent"] as? String,
                           let change = Double(changePercentStr) {
                            firstChange = change
                        }
                    }
                    dispatchGroup.leave()
                }
                task1.resume()
            } else {
                dispatchGroup.leave()
            }
        }
        
        // 코인2 가격 및 일일 변화율 요청
        dispatchGroup.enter()
        if coin2IsKRW {
            let coin = secondSelectedCoin.apiSymbol.replacingOccurrences(of: "KRW", with: "")
            let market = "KRW-\(coin)"
            let urlString2 = "https://api.upbit.com/v1/ticker?markets=\(market)"
            if let url2 = URL(string: urlString2) {
                let task2 = URLSession.shared.dataTask(with: url2) { data, response, error in
                    if let data = data, error == nil,
                       let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let firstObject = jsonArray.first {
                        if let price = firstObject["trade_price"] as? Double {
                            secondPrice = price
                        }
                        if let changeRate = firstObject["signed_change_rate"] as? Double {
                            secondChange = changeRate * 100
                        }
                    }
                    dispatchGroup.leave()
                }
                task2.resume()
            } else {
                dispatchGroup.leave()
            }
        } else {
            // Binance: 24hr 엔드포인트 (일일 변화율 포함)
            let urlString2 = "https://api.binance.com/api/v3/ticker/24hr?symbol=\(secondSelectedCoin.apiSymbol)"
            if let url2 = URL(string: urlString2) {
                let task2 = URLSession.shared.dataTask(with: url2) { data, response, error in
                    if let data = data, error == nil,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let priceString = json["lastPrice"] as? String,
                           let price = Double(priceString) {
                            secondPrice = price
                        }
                        if let changePercentStr = json["priceChangePercent"] as? String,
                           let change = Double(changePercentStr) {
                            secondChange = change
                        }
                    }
                    dispatchGroup.leave()
                }
                task2.resume()
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            let formatter = NumberFormatter()
            formatter.usesSignificantDigits = true
            formatter.maximumSignificantDigits = 4
            formatter.numberStyle = .decimal
            
            let changeFormatter = NumberFormatter()
            changeFormatter.numberStyle = .decimal
            changeFormatter.maximumFractionDigits = 1
            
            let formattedFirst = firstPrice != nil ? formatter.string(from: NSNumber(value: firstPrice!)) ?? "\(firstPrice!)" : "Error"
            let formattedSecond = secondPrice != nil ? formatter.string(from: NSNumber(value: secondPrice!)) ?? "\(secondPrice!)" : "Error"
            let formattedChange1 = firstChange != nil ? changeFormatter.string(from: NSNumber(value: firstChange!)) ?? "\(firstChange!)" : "Error"
            let formattedChange2 = secondChange != nil ? changeFormatter.string(from: NSNumber(value: secondChange!)) ?? "\(secondChange!)" : "Error"
            
            let coin1Display = (self?.selectedCoin.display ?? "코인1").replacingOccurrences(of: "USDT", with: "").replacingOccurrences(of: "KRW", with: "")
            let coin2Display = (self?.secondSelectedCoin.display ?? "코인2").replacingOccurrences(of: "USDT", with: "").replacingOccurrences(of: "KRW", with: "")
            
            let coin1PriceText = coin1IsKRW ? "\(coin1Display): \(formattedFirst) KRW " : "\(coin1Display): $\(formattedFirst) "
            let coin2PriceText = coin2IsKRW ? "\(coin2Display): \(formattedSecond) KRW " : "\(coin2Display): $\(formattedSecond) "
            
            let coin1ChangeText = firstChange != nil ? "\(formattedChange1)%" : "Error"
            let coin2ChangeText = secondChange != nil ? "\(formattedChange2)%" : "Error"
            
            // 양수일 경우 연두색, 음수일 경우 진한핑크색으로 표기합니다.
            let coin1ChangeColor: NSColor = (firstChange ?? 0) >= 0 ? NSColor.systemGreen : NSColor.systemPink
            let coin2ChangeColor: NSColor = (secondChange ?? 0) >= 0 ? NSColor.systemGreen : NSColor.systemPink
            
            let fullAttributed = NSMutableAttributedString(string: coin1PriceText)
            let coin1ChangeAttr = NSAttributedString(string: coin1ChangeText, attributes: [.foregroundColor: coin1ChangeColor])
            fullAttributed.append(coin1ChangeAttr)
            
            fullAttributed.append(NSAttributedString(string: "  "))
            fullAttributed.append(NSAttributedString(string: coin2PriceText))
            let coin2ChangeAttr = NSAttributedString(string: coin2ChangeText, attributes: [.foregroundColor: coin2ChangeColor])
            fullAttributed.append(coin2ChangeAttr)
            
            self?.statusItem.button?.attributedTitle = fullAttributed
        }
    }
    
    // 앱 종료 메소드
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

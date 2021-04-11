//
//  ContentView.swift
//  Sugars
//
//  Created by Nat Dean-Lewis on 11/04/2021 AD.
//
import UserNotifications

import SwiftUI

public struct ContentView: View {
    
    @State var allEntries: [AnEntry] = []
    @State var latestSgv: Double = -1.0
    @State var latestDirection: String = "Loading"
    @State var minsSince: Int = -1
    @State var latestMills: Double = 0.0
    @State var deltaString: String = ""
    @State var delta: Double = 0.0
    

    let low = 4.5
    let high = 8.0
    let veryLow = 4.0
    let veryHigh = 9.0
    let slowChange = 0.05
    let fastChange = 0.1
        
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    
    public var body: some View {
        
        ZStack {
            if latestSgv == -1.0{
                Color.white
            } else if minsSince >= 6 {
//                if data more than 6 mins out of date
                Color.gray
            } else if minsSince >= 60 {
//                if data more than an hour out of date
                Color.black
            } else if latestSgv >= low && latestSgv <= high {
                Color.green
            } else if latestSgv >= veryLow && latestSgv <= veryHigh {
                Color.yellow
            } else {
                Color.red
            }
            VStack {
                
//                  Display sensor reading (or retreiving message if none received)
                if latestSgv > 0 {
                    Text(String(latestSgv))
                        .font(Font.custom("Sgv", size: 500))
                        .foregroundColor(.black)
                } else {
                    Text("Connecting...")
                        .font(Font.custom("Loading", size: 50))
                        .foregroundColor(.black)
                }

//                  Sugar direction arrow:
//                Image(latestDirection)
                
//                if delta == 0.0 {
//                    Text(deltaString)
//                        .font(Font.custom("Delta", size: 200))
//                        .foregroundColor(.black)
//                        .background(Color.purple)
//                } else
                if abs(delta) < slowChange {
                    Text(deltaString)
                        .font(Font.custom("Delta", size: 200))
                        .foregroundColor(.black)
                        .padding()


                } else if abs(delta) < fastChange && latestSgv >= veryLow && latestSgv <= veryHigh {
                    Text(deltaString)
                        .font(Font.custom("Delta", size: 200))
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(50)
                } else if deltaString != "" {
                    Text(deltaString)
                        .font(Font.custom("Delta", size: 200))
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(50)
                }
//                  Display time since displayed sensor reading:
//                if minsSince == 0 {
//                    Text("Just now")
//                            .foregroundColor(.black)
//
//                } else if minsSince == 1 {
//                    Text("1 min ago")
//                            .foregroundColor(.black)
//
//                } else if minsSince == -1 {
//                    Text("")
//                            .foregroundColor(.black)
//
//                } else if minsSince < 60 {
//                    Text(String(minsSince) + " mins ago")
//                            .foregroundColor(.black)
//
//                } else {
//                    Text("Over an hour ago")
//                            .foregroundColor(.black)
//
//                }
    //

            }
//            List(allEntries) { AnEntry in
//                Text(String(AnEntry.sgv))
//            }
        }
        
//      Call API to get data every time timer goes off (every second)
        .onReceive(timer) { _ in
            apiCall().getEntries { (allEntries) in
                self.allEntries = allEntries
//                evaluates true if there is a new reading:
                if self.latestMills != Double(allEntries[0].mills) {
                    self.latestSgv = round(allEntries[0].sgv/18*10)/10
                    let previousSgv = round(allEntries[1].sgv/18*10)/10
//                    delta is rate of change in Sgv per minute
                    let minutesBetween = Double(allEntries[0].mills - allEntries[1].mills)/60000
                    self.delta = round((allEntries[0].sgv-allEntries[1].sgv)/18/minutesBetween*100)/100
                    if delta == 0 {
                        self.deltaString = "∆ 0"
                    } else if delta < 0 {
                        self.deltaString = "∆ " + String(delta)
                    } else {
                        self.deltaString = "∆ +" + String(abs(delta))
                    }
                    self.latestDirection = allEntries[0].direction
                    self.latestMills = Double(allEntries[0].mills)
                    let content = UNMutableNotificationContent()
                    if latestSgv < veryLow {
                        content.title = "🚨 Very low! 🚨"
                    } else if latestSgv > veryHigh {
                        content.title = "🚨 Very high! 🚨"
                    } else if latestSgv < low {
                        content.title = "A little low..."
                    } else if latestSgv > high {
                        content.title = "A little high..."
                    } else if delta >= fastChange {
                        content.title = "⚠️ Fast rise! ⚠️"
                    } else if delta <=  -1*fastChange {
                        content.title = "⚠️ Fast drop! ⚠️"
                    } else if delta >= slowChange {
                        content.title = "Going up... "
                    } else if delta <= -1 * slowChange {
                        content.title = "Going down..."
                    } else {
                        content.title = "Looking good! 👍🏻"
                    }
                    content.subtitle = String(latestSgv)
//                    if in the Internatiol Diabetes Federation's target range for people WITHOUT diabetes:
                    if latestSgv >= 4.0 && latestSgv<=5.9 {
                        content.subtitle += " 👌🏻 "
                    }
                    content.subtitle += " | " + deltaString
                    if delta == 0 {
                        content.subtitle += " 👏"
                    }


                    // show this notification five seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                    print("was", previousSgv, "now", latestSgv, "delta", delta, minutesBetween, "min gap")
                }
//                this next block can be moved inside the if statement above if the secsSince readout is not required. (changing latestMillsHiden to latestMills)
                let latestMillsHidden = Double(allEntries[0].mills)
               
                let readingSecs = latestMillsHidden / 1000
                let now = Date()
                let readingDate = Date(timeIntervalSince1970: readingSecs)
                let secsSince = now.timeIntervalSince(readingDate)
                self.minsSince = Int(floor(secsSince/60))
                print(secsSince)
                
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
            ContentView()
                .previewLayout(.fixed(width: 1300.0, height: 800.0))
    }
}


class apiCall {
    func getEntries(completion:@escaping ([AnEntry]) -> ()) {
        guard let url = URL(string: "https://nightscout-site.herokuapp.com/api/v1/entries.json?count=10") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            let entries = try! JSONDecoder().decode([AnEntry].self, from: data!)
            DispatchQueue.main.async {
                completion(entries)
            }
        }
        .resume()
    }
    
}


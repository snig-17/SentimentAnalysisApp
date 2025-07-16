//
//  ViewController.swift
//
//
//  Created by Snigdha Tiwari on 16-07-2025.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var emojiLabel: UILabel!
    
    private let tweetCount = 100
    
    private let sentimentClassifier: TweetSentimentClassifier = {
        
        do {
            let config = MLModelConfiguration()
            return try TweetSentimentClassifier(configuration: config)
        } catch {
            fatalError("Couldn't create a MLModel \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func predictPressed(_ sender: UIButton) {
        fetchTweets()
    }
    
    struct TweetData: Codable {
        let data: [Tweet]
    }

    struct Tweet: Codable {
        let text: String
    }

    func fetchTweets() {
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let textInputText = textInput.text else { return }
        
        var request = URLRequest(url: URL(string: "https://api.twitter.com/2/tweets/search/recent?max_results=\(tweetCount)&query=\(textInputText)")!, timeoutInterval: Double.infinity)
        
        request.addValue("AAAAAAAAAAAAAAAAAAAAAD5a3AEAAAAAYsbmYu%2FjCecW%2BNm8jGz7O13YSmw%3Dilx5t0bJcGRX0eOLORtAzCPiMshUTgnnYRw4361hVMx4EqzSM7", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard let data = data else {
                print(String(describing: error))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TweetData.self, from: data)
                let tweets = decodedResponse.data.map { TweetSentimentClassifierInput(text: $0.text) }
                self.makePredictions(with: tweets)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        task.resume()
        semaphore.wait()
    }
    
    func makePredictions(with tweets: [TweetSentimentClassifierInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            
            var sentimentScore = 0
            
            for prediction in predictions {
                let sentiment = prediction.label
                
                if sentiment == "Pos" {
                    sentimentScore += 1
                } else if sentiment == "Neg" {
                    sentimentScore -= 1
                }
            }
            
            updateUI(with: sentimentScore)
            
        } catch {
            print("Error making predictions \(error)")
        }
    }
    
    func updateUI(with sentimentScore: Int) {
        DispatchQueue.main.async {
            if sentimentScore > 20 {
                self.emojiLabel.text = "😍"
            } else if sentimentScore > 10 {
                self.emojiLabel.text = "😀"
            } else if sentimentScore > 0  {
                self.emojiLabel.text = "🙂"
            } else if sentimentScore == 0  {
                self.emojiLabel.text = "😐"
            } else if sentimentScore > -10  {
                self.emojiLabel.text = "😕"
            } else if sentimentScore > -20  {
                self.emojiLabel.text = "😡"
            } else  {
                self.emojiLabel.text = "🤮"
            }
        }
    }
    
    
}

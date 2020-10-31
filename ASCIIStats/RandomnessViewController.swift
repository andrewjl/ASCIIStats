//
//  RandomnessViewController.swift
//  ASCIIStats
//
//  Created by Andrew Lauer Barinov on 10/29/20.
//

import UIKit

struct RandomnessRun {
    var range:ClosedRange<Int> = (0...1)
    
    var heads: UInt
    var tails: UInt
    
    mutating func flip() {
        let r = self.range.randomElement()
        
        switch r {
            case 0:
                self.heads += 1
            case 1:
                self.tails += 1
            default:
                break
        }
    }
    
    var starredHeads: String {
        return String(repeating: "*", count: Int(self.heads))
    }
    
    var starredTails: String {
        return String(repeating: "*", count: Int(self.tails))
    }
    
    var probabilityDistributionHeads: String {
        return String(repeating: "◼︎", count: 10)
    }
    
    var probabilityDistributionTails: String {
        return String(repeating: "◼︎", count: 10)
    }
}

struct ReactiveLabel {
    var element: UILabel
    var update: (String) -> ()
}

class RandomnessViewController: UIViewController {
    
    var idealDistributionStack: UIStackView
    var outcomeDistributionStack: UIStackView
    
    var headsOutcomesLabel: UILabel
    var tailsOutcomesLabel: UILabel
    
    var headsIdealLabel: UILabel
    var tailsIdealLabel: UILabel
    
    var flipOnceAction: UIAction {
        return UIAction { (action) in
            self.run.flip()
        }
    }
    
    var flipHundredTimesAction: UIAction {
        return UIAction { (action) in
            for i in 0..<100 {
                
                let time = DispatchTime.now().advanced(by: .seconds(i))
                
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.run.flip()
                }
            }
        }
    }
    
    var displayLink: CADisplayLink?
    
    var flipOnceButton: UIButton?
    var flipHundredTimesButton: UIButton?
    
    var run: RandomnessRun
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.idealDistributionStack = UIStackView()
        self.outcomeDistributionStack = UIStackView()
        
        self.headsOutcomesLabel = UILabel()
        self.tailsOutcomesLabel = UILabel()
        
        self.headsIdealLabel = UILabel()
        self.tailsIdealLabel = UILabel()
        
        self.run = RandomnessRun(heads: 0, tails: 0)
        
        super.init(nibName: nibNameOrNil,
                   bundle: nibBundleOrNil)
        
        self.displayLink = CADisplayLink(target: self,
                                         selector: #selector(updateLabels))
    }
    
    required init?(coder: NSCoder) {
        self.idealDistributionStack = UIStackView()
        self.outcomeDistributionStack = UIStackView()
        
        self.headsOutcomesLabel = UILabel()
        self.tailsOutcomesLabel = UILabel()
        
        self.headsIdealLabel = UILabel()
        self.tailsIdealLabel = UILabel()
        
        self.run = RandomnessRun(heads: 0, tails: 0)
        
        super.init(coder: coder)
        
        self.displayLink = CADisplayLink(target: self,
                                         selector: #selector(updateLabels))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        self.outcomeDistributionStack.translatesAutoresizingMaskIntoConstraints = false
        self.outcomeDistributionStack.axis = .vertical
        self.outcomeDistributionStack.distribution = .equalSpacing
        self.outcomeDistributionStack.layoutMargins = UIEdgeInsets(top: 48,
                                                                   left: 8,
                                                                   bottom: 48,
                                                                   right: 8)
        self.outcomeDistributionStack.isLayoutMarginsRelativeArrangement = true
        
        self.headsOutcomesLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)
        self.tailsOutcomesLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)
        
        let outcomeDistributionTitleLabel = UILabel()
        outcomeDistributionTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1).withSize(28.0)
        outcomeDistributionTitleLabel.text = "Outcome Distribution"
        
        self.outcomeDistributionStack.addArrangedSubview(outcomeDistributionTitleLabel)
        self.outcomeDistributionStack.addArrangedSubview(self.headsOutcomesLabel)
        self.outcomeDistributionStack.addArrangedSubview(self.tailsOutcomesLabel)
        
        let idealDistributionTitleLabel = UILabel()
        idealDistributionTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1).withSize(28.0)
        idealDistributionTitleLabel.text = "True Probabilities"
        
        self.idealDistributionStack.translatesAutoresizingMaskIntoConstraints = false
        self.idealDistributionStack.axis = .vertical
        self.idealDistributionStack.distribution = .equalSpacing
        self.idealDistributionStack.layoutMargins = UIEdgeInsets(top: 48,
                                                                 left: 8,
                                                                 bottom: 48,
                                                                 right: 8)
        self.idealDistributionStack.isLayoutMarginsRelativeArrangement = true
        
        self.headsIdealLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)
        self.tailsIdealLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)
        
        self.idealDistributionStack.addArrangedSubview(idealDistributionTitleLabel)
        self.idealDistributionStack.addArrangedSubview(headsIdealLabel)
        self.idealDistributionStack.addArrangedSubview(tailsIdealLabel)
        
        let flipOnceButton = UIButton(primaryAction: self.flipOnceAction)
        let flipHundredTimesButton = UIButton(primaryAction: self.flipHundredTimesAction)
        
        flipOnceButton.translatesAutoresizingMaskIntoConstraints = false
        flipHundredTimesButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.outcomeDistributionStack)
        self.view.addSubview(self.idealDistributionStack)
        self.view.addSubview(flipOnceButton)
        self.view.addSubview(flipHundredTimesButton)
        
        self.outcomeDistributionStack.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.outcomeDistributionStack.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.outcomeDistributionStack.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.outcomeDistributionStack.bottomAnchor.constraint(equalTo: self.idealDistributionStack.topAnchor).isActive = true
        
        self.idealDistributionStack.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.idealDistributionStack.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        self.idealDistributionStack.heightAnchor.constraint(equalTo: self.outcomeDistributionStack.heightAnchor).isActive = true
        
        flipOnceButton.topAnchor.constraint(equalTo: self.idealDistributionStack.bottomAnchor, constant: 64.0).isActive = true
        flipHundredTimesButton.topAnchor.constraint(equalTo: flipOnceButton.topAnchor).isActive = true
        
        flipOnceButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0).isActive = true
        flipHundredTimesButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0).isActive = true
        
        flipOnceButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0).isActive = true
        flipHundredTimesButton.leadingAnchor.constraint(equalTo: flipOnceButton.trailingAnchor, constant: 16.0).isActive = true
        
        flipOnceButton.setTitle("Flip Once", for: .normal)
        flipHundredTimesButton.setTitle("Flip 100 Times", for: .normal)
        
        self.flipOnceButton = flipOnceButton
        self.flipHundredTimesButton = flipHundredTimesButton
        
        if let dl = self.displayLink {
            dl.preferredFramesPerSecond = 30
            dl.add(to: .main,
                   forMode: .default)
        }
        
        self.update()
    }
    
    func update() {
        let headsIdealString = String(repeating: "*", count: 10)
        self.headsIdealLabel.text = "Heads: " + headsIdealString
        
        let tailsIdealString = String(repeating: "*", count: 10)
        self.tailsIdealLabel.text = "Tails: " + tailsIdealString
        
        
    }
    
    
    @objc func updateLabels() {
        let headsOutcomeString = String(repeating: "*", count: Int(self.run.heads))
        self.headsOutcomesLabel.text = "Heads \(self.run.heads): " + headsOutcomeString
        
        let tailsOutcomeString = String(repeating: "*", count: Int(self.run.tails))
        self.tailsOutcomesLabel.text = "Tails: \(self.run.tails)" + tailsOutcomeString
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

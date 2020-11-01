//
//  RandomnessViewController.swift
//  ASCIIStats
//
//  Created by Andrew Lauer Barinov on 10/29/20.
//

import UIKit

struct RandomnessRun {
    var range:ClosedRange<Int> = (0...1)
    
    var cycles: UInt = 0
    
    var heads: UInt
    var tails: UInt
    
    var isFlipping: Bool = false
    var flippingEnd: UInt = 0
    
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
        
        self.cycles += 1
    }
    
    mutating func flipAHundredTimes() {
        
        self.flippingEnd = self.cycles + 100
        self.isFlipping = true
        
//        for i in 0..<100 {
//            let time = DispatchTime.now().advanced(by: .seconds(i))
//
//            DispatchQueue.main.asyncAfter(deadline: time) {
//                self.flip()
//            }
//        }
    }
    
    mutating func tick() {
        if self.cycles <= self.flippingEnd && self.isFlipping == true {
            self.flip()
        } else {
            self.isFlipping = false
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
    
    var flipAction: Change<RandomnessRun> {
        return { $0.flip() }
    }
    
    var tickAction: Change<RandomnessRun> {
        return { $0.tick() }
    }
    
    var isTicking: Bool {
        return self.isFlipping
    }
    
    var flipHundredTimesAction: Change<RandomnessRun> {
        return { $0.flipAHundredTimes() }
    }
}

struct ReactiveLabel {
    var element: UILabel
    var update: (String) -> ()
}

class RandomnessInstrument {
    var viewController: UIViewController!
    var reactiveViewController: ReactiveElement<UIViewController, RandomnessRun>!
    
    var state: RandomnessRun {
        didSet {
            self.reactiveViewController.update(oldValue, self.state)
        }
    }
    
    init(initial state: RandomnessRun,
         blueprint: Blueprint<UIViewController, RandomnessRun>) {
        self.state = state
        
        let context = PresentationContext(state: state,
                                          reduce: { [unowned self] change in self.process(change) },
                                          pushViewController: {vc in },
                                          popViewController: {})
        
        self.reactiveViewController = blueprint(context)
        self.viewController = self.reactiveViewController.element
        self.reactiveViewController.update(state, state)
    }
    
    func process(_ change: Change<RandomnessRun>) {
        change(&self.state)
    }
}

class RandomnessViewController: UIViewController {
    
    var idealDistributionStack: UIStackView?
    var outcomeDistributionStack: UIStackView?
    
    var headsOutcomesLabel: UILabel?
    var tailsOutcomesLabel: UILabel?
    
    var headsIdealLabel: UILabel?
    var tailsIdealLabel: UILabel?
    
    var displayLinkHolder: DisplayLinkHolder?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
    }
    
//    func update() {
//        let headsIdealString = String(repeating: "*", count: 10)
//        self.headsIdealLabel?.text = "Heads: " + headsIdealString
//
//        let tailsIdealString = String(repeating: "*", count: 10)
//        self.tailsIdealLabel?.text = "Tails: " + tailsIdealString
//
//
//    }
//
//
//    @objc func updateLabels() {
//        let headsOutcomeString = String(repeating: "*", count: Int(self.run.heads))
//        self.headsOutcomesLabel?.text = "Heads \(self.run.heads): " + headsOutcomeString
//
//        let tailsOutcomeString = String(repeating: "*", count: Int(self.run.tails))
//        self.tailsOutcomesLabel?.text = "Tails: \(self.run.tails)" + tailsOutcomeString
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

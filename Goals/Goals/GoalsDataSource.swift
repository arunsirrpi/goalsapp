//
//  GoalsDataSource.swift
//  Goals
//
//  Created by Manuel M T Chakravarty on 22/06/2016.
//  Copyright © 2016 Chakravarty & Keller. All rights reserved.
//

import UIKit


private let kGoalTableCell = "GoalTableCell"
private let size           = CGSize(width: 35, height: 35)

class GoalsDataSource: NSObject {

  @IBOutlet private weak var tableView: UITableView?

  fileprivate var goals:            Goals = []          // Cache the last model data we observed.
  fileprivate var goalsObservation: Observation<Goals>!

  override init() {
    super.init()

    goalsObservation = model.observe(withContext: self){ context, goals in
      context.goals = goals
      context.tableView?.reloadData()
    }
  }

  /// Retrieve the goal at the given index path in the model data, if available.
  ///
  func goal(at indexPath: IndexPath) -> (goal: Goal, isActive: Bool)? {
    let idx = indexPath.item
    if idx >= goals.startIndex && idx < goals.endIndex {
      return (goal: goals[idx].goal, isActive: goals[idx].progress != nil)
    } else { return nil }
  }

  /// Flag array indicating for each goal whether it is active.
  ///
  var goalsActivity: [Bool] { return goals.map{ $0.progress != nil } }

  func commitGoalsActivity(_ goalsActivity: [Bool]) {
    edits.announce(change: .setActivity(activity: goalsActivity))
  }
}

extension GoalsDataSource: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return goals.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kGoalTableCell) ?? UITableViewCell(),
        goal = self.goal(at: indexPath) ?? (goal: Goal(), isActive: false)

    let rect = CGRect(origin: CGPoint.zero, size: size),
        path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
    UIGraphicsBeginImageContext(size)
    goal.goal.colour.setFill()
    path.fill()
    cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    cell.textLabel?.text       = goal.goal.title
    cell.detailTextLabel?.text = goal.goal.frequencyPerInterval
    cell.editingAccessoryType  = goal.isActive ? .checkmark : .none
    return cell
  }

  func tableView(_ tableView: UITableView,
                 commit editingStyle: UITableViewCellEditingStyle,
                 forRowAt indexPath: IndexPath)
  {
    guard let goal = self.goal(at: indexPath) else { return }

      // Remove goal from model without updating our local cache.
    goalsObservation.disable{
      edits.announce(change: .delete(goal: goal.goal))
    }

      // Independently remove it from our local model cache and the UI to properly animate.
    goals.remove(at: indexPath.item)
    tableView.deleteRows(at: [indexPath], with: .left)
  }
}

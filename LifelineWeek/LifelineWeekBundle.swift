//
//  LifelineWeekBundle.swift
//  LifelineWeek
//
//  Created by Sam Manh Cuong on 24/3/26.
//

import WidgetKit
import SwiftUI

@main
struct LifelineWeekBundle: WidgetBundle {
    var body: some Widget {
        LifelineWeek()
        LifelineWeekControl()
        LifelineWeekLiveActivity()
    }
}

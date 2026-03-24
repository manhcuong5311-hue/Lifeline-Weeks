//
//  LifelineWeekLiveActivity.swift
//  LifelineWeek
//
//  Created by Sam Manh Cuong on 24/3/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LifelineWeekAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LifelineWeekLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LifelineWeekAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LifelineWeekAttributes {
    fileprivate static var preview: LifelineWeekAttributes {
        LifelineWeekAttributes(name: "World")
    }
}

extension LifelineWeekAttributes.ContentState {
    fileprivate static var smiley: LifelineWeekAttributes.ContentState {
        LifelineWeekAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LifelineWeekAttributes.ContentState {
         LifelineWeekAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LifelineWeekAttributes.preview) {
   LifelineWeekLiveActivity()
} contentStates: {
    LifelineWeekAttributes.ContentState.smiley
    LifelineWeekAttributes.ContentState.starEyes
}

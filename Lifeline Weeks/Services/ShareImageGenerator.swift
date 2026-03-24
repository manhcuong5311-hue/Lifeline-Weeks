import SwiftUI

@MainActor
struct ShareImageGenerator {

    static func generate(
        weeks:               [LifeWeek],
        progress:            Double,
        weeksLived:          Int,
        lifeExpectancyYears: Int,
        config:              ShareConfig = ShareConfig()
    ) -> UIImage? {
        let card = ShareCardView(
            weeks:               weeks,
            progress:            progress,
            weeksLived:          weeksLived,
            lifeExpectancyYears: lifeExpectancyYears,
            config:              config
        )
        let renderer     = ImageRenderer(content: card)
        renderer.scale   = config.layout.exportScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

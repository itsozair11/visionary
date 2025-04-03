import Foundation
import CoreData

extension Album {
    var photosArray: [Classification] {
        let set = photos as? Set<Classification> ?? []
        return set.sorted {
            let date1 = $0.timestamp ?? Date.distantPast
            let date2 = $1.timestamp ?? Date.distantPast
            return date1 < date2
        }
    }
}

import Foundation

protocol BaseApiRequestQuery {
    
}

extension BaseApiRequestQuery {
    func toDictionary() -> [String : Any] {
        var dictionary: [String : Any] = [:]
        for children in Mirror(reflecting: self).children {
            guard let key = children.label else { continue }
            dictionary[key] = children.value
        }
        return dictionary
    }
}


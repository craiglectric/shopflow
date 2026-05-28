import Foundation

public enum CommType: String, Codable, CaseIterable, Identifiable, Sendable {
    case callOutbound
    case callInbound
    case text
    case email
    case inPerson

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .callOutbound: return "Call Out"
        case .callInbound:  return "Call In"
        case .text:         return "Text"
        case .email:        return "Email"
        case .inPerson:     return "In Person"
        }
    }
}

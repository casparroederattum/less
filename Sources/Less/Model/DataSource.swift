import Foundation

/// One place Less may look. Each gets its own permission card, in this order.
/// The order goes from least to most personal, so trust is built before it is asked for.
enum DataSource: String, Codable, CaseIterable, Identifiable {
    case apps, screenTime, browsers, loginItems, notifications, bluetooth, localNetwork

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apps: return "Your apps"
        case .screenTime: return "Time spent in apps"
        case .browsers: return "Websites"
        case .loginItems: return "What starts on its own"
        case .notifications: return "Who can interrupt you"
        case .bluetooth: return "Devices you carry"
        case .localNetwork: return "Devices at home"
        }
    }

    var reads: String {
        switch self {
        case .apps:
            return "The names of the apps in your Applications folder, and when you last opened each one."
        case .screenTime:
            return "How many minutes a day you spend in each app, and how often you open it, over the last seven days."
        case .browsers:
            return "Which websites you visit in Safari and Chrome, and roughly how long you stay. Only the site name, like youtube.com."
        case .loginItems:
            return "Apps that open when you log in, or keep running quietly in the background."
        case .notifications:
            return "Which apps are allowed to send you notifications."
        case .bluetooth:
            return "The names of Bluetooth devices paired with this Mac, like headphones or a fitness band."
        case .localNetwork:
            return "The names of speakers, TVs and hubs that announce themselves on your home network."
        }
    }

    var why: String {
        switch self {
        case .apps: return "Apps you never open are the easiest things to let go of."
        case .screenTime: return "Time is the honest measure. It shows where your days actually go."
        case .browsers: return "A lot of time online doesn't live in an app."
        case .loginItems: return "Things that are always on are easy to forget about."
        case .notifications: return "Every interruption costs a little attention."
        case .bluetooth: return "Some of the most persistent technology is the kind you wear."
        case .localNetwork: return "A home can fill up with screens and speakers without anyone deciding it should."
        }
    }

    var never: String {
        switch self {
        case .apps: return "Less doesn't open your apps or look inside them."
        case .screenTime: return "Less reads totals only. Nothing about what you did inside an app."
        case .browsers: return "Less never keeps full addresses, page titles or searches."
        case .loginItems: return "Less doesn't change or turn off anything for you."
        case .notifications: return "Less never reads the notifications themselves."
        case .bluetooth: return "Less doesn't connect to your devices or read anything from them."
        case .localNetwork: return "Less only listens for names. It doesn't connect to anything or send anything out."
        }
    }

    /// Shown under the card when macOS will ask its own question.
    var systemNote: String? {
        switch self {
        case .loginItems:
            return "Your Mac may ask whether Less can use System Events. That is how it sees your login items."
        case .bluetooth:
            return "Your Mac will ask once whether Less may use Bluetooth."
        case .localNetwork:
            return "Your Mac will ask once whether Less may find devices on your network."
        default:
            return nil
        }
    }

    /// Screen Time and Safari sit behind Full Disk Access, which only the person can switch on.
    var needsFullDiskAccess: Bool { self == .screenTime || self == .browsers }

    var progressText: String {
        switch self {
        case .apps: return "Looking at your installed apps"
        case .screenTime: return "Looking at how long you spend in apps"
        case .browsers: return "Looking at the websites you visit"
        case .loginItems: return "Looking at what starts on its own"
        case .notifications: return "Looking at which apps can interrupt you"
        case .bluetooth: return "Looking for Bluetooth devices"
        case .localNetwork: return "Listening for devices on your home network"
        }
    }
}

/// What one source actually gave us. This is what the "What Less knows" view lists.
struct SourceReport: Codable, Identifiable {
    var source: DataSource
    var readable: Bool
    /// Plain sentence, e.g. "39 app names and when you last opened each one."
    var summary: String

    var id: String { source.rawValue }
}

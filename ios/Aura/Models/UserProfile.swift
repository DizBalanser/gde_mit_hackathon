import Foundation

struct UserProfile: Codable {
    var uid: String
    var name: String
    var phoneNumber: String        // E.164 format, e.g. "+12345678900"
    var preferredCallHour: Int     // 0–23 in user's local timezone
    var preferredCallMinute: Int   // 0–59 in user's local timezone
    var timezone: String           // e.g. "America/New_York"
    var preferredCallUTCHour: Int
    var preferredCallUTCMinute: Int
    var createdAt: Date

    init(uid: String) {
        self.uid = uid
        self.name = ""
        self.phoneNumber = ""
        self.timezone = TimeZone.current.identifier
        self.createdAt = Date()

        // Default: 9:00 AM local time
        let utc = Self.localToUTC(hour: 9, minute: 0)
        self.preferredCallHour = 9
        self.preferredCallMinute = 0
        self.preferredCallUTCHour = utc.hour
        self.preferredCallUTCMinute = utc.minute
    }

    /// Converts a local hour/minute to UTC hour/minute
    static func localToUTC(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        // Use today as the date base so DST offset is correct
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.year = today.year
        comps.month = today.month
        comps.day = today.day

        guard let localDate = Calendar.current.date(from: comps) else { return (hour, minute) }

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let utcHour = utcCal.component(.hour, from: localDate)
        let utcMinute = utcCal.component(.minute, from: localDate)
        return (utcHour, utcMinute)
    }

    /// Returns the preferred call time as a displayable string in the local timezone
    var displayCallTime: String {
        var comps = DateComponents()
        comps.hour = preferredCallHour
        comps.minute = preferredCallMinute
        guard let date = Calendar.current.date(from: comps) else { return "\(preferredCallHour):\(String(format: "%02d", preferredCallMinute))" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

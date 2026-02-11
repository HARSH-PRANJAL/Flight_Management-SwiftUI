import Foundation

func formatDate(_ date: Date,
                format: String,
                timeZone: TimeZone? = nil,
                locale: Locale = .current) -> String {
    
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.locale = locale
    
    if let timeZone {
        formatter.timeZone = timeZone
    }
    
    return formatter.string(from: date)
}

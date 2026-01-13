import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: PomodoroViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Stats Header
            HStack(spacing: 0) {
                StatItem(title: "Sessions", value: "\(viewModel.totalSessions)")
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 24)
                StatItem(title: "Pauses", value: "\(viewModel.totalPauses)")
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 24)
                StatItem(title: "Total Time", value: formatDuration(viewModel.totalTime))
            }
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // History List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.history.reversed()) { session in
                        HStack {
                            Circle()
                                .fill(Color(session.phase.color))
                                .frame(width: 8, height: 8)
                            
                            Text(session.phase.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(formatDate(session.date))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(formatDuration(session.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

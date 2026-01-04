import SwiftUI
import Combine
import AppKit

@MainActor
@Observable
final class PomodoroViewModel {
    var currentPhase: PomodoroPhase = .work
    var timeRemaining: TimeInterval = PomodoroPhase.work.duration
    var isActive: Bool = false
    var islandState: IslandState = .collapsed
    var isHovering: Bool = false
    
    var onStateChange: ((Bool) -> Void)?
    
    private var timer: Timer?
    private var collapseTask: Task<Void, Never>?
    private var endTime: Date?
    
    var progress: Double {
        let total = currentPhase.duration
        return (total - timeRemaining) / total
    }
    
    var timeString: String {
        let totalSeconds = Int(max(0, timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if islandState == .collapsed && isActive {
            return String(format: "%02d:%d0", minutes, seconds / 10)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isExpanded: Bool {
        islandState.isExpanded
    }
    
    init() {
    }
    
    func toggleTimer() {
        isActive.toggle()
        if isActive {
            endTime = Date().addingTimeInterval(timeRemaining)
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        stopTimer()
        
        let interval: TimeInterval = islandState == .expanded ? 1.0 : 10.0
        
        // Immediate tick to update UI
        tick()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        timer?.tolerance = interval * 0.1
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard let endTime = endTime else { return }
        let remaining = endTime.timeIntervalSinceNow
        
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            timeRemaining = 0
            completePhase()
        }
    }
    
    private func completePhase() {
        playCompletionSound(for: currentPhase)
        
        isActive = false
        stopTimer()
        endTime = nil
        skipPhase()
    }
    
    private func playCompletionSound(for phase: PomodoroPhase) {
        let soundName: String
        let repeatCount: Int
        
        switch phase {
        case .work:
            soundName = "Glass"
            repeatCount = 3
        case .shortBreak, .longBreak:
            soundName = "Bottle"
            repeatCount = 2
        }
        
        Task {
            for _ in 0..<repeatCount {
                NSSound(named: soundName)?.play()
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }
    }
    
    func skipPhase() {
        stopTimer()
        isActive = false
        endTime = nil
        
        switch currentPhase {
        case .work:
            currentPhase = .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .work
        }
        
        timeRemaining = currentPhase.duration
    }
    
    func resetTimer() {
        stopTimer()
        isActive = false
        endTime = nil
        timeRemaining = currentPhase.duration
    }
    
    func onHover(_ hovering: Bool) {
        collapseTask?.cancel()
        collapseTask = nil

        if hovering {
            isHovering = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                islandState = .expanded
            }
            onStateChange?(true)
            
            // Switch to high frequency updates when expanded
            if isActive {
                startTimer()
            }
        } else {
            collapseTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }

                isHovering = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    islandState = .collapsed
                }
                onStateChange?(false)
                
                // Switch to low frequency updates when collapsed
                if self.isActive {
                    self.startTimer()
                }
            }
        }
    }
}
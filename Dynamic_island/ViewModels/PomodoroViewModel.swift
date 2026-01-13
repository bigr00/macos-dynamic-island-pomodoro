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
    
    var history: [PomodoroSession] = []
    var showHistory: Bool = false {
        didSet {
            onHistoryToggle?(showHistory)
        }
    }
    
    var totalSessions: Int {
        history.filter { $0.phase == .work }.count
    }
    
    var totalPauses: Int {
        history.filter { $0.phase == .shortBreak || $0.phase == .longBreak }.count
    }
    
    var totalTime: TimeInterval {
        history.reduce(0) { $0 + $1.duration }
    }
    
    var onStateChange: ((Bool) -> Void)?
    var onHistoryToggle: ((Bool) -> Void)?
    
    private var timer: Timer?
    private var collapseTask: Task<Void, Never>?
    private var endTime: Date?
    
    private var alarmTimer: Timer?
    var isAlarming: Bool = false
    
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
        if isAlarming {
            stopAlarm()
            return
        }
        
        isActive.toggle()
        if isActive {
            endTime = Date().addingTimeInterval(timeRemaining)
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
        isAlarming = false
    }
    
    private func startTimer() {
        stopTimer()
        
        let interval: TimeInterval = islandState == .expanded ? 1.0 : 10.0
        
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
        history.append(PomodoroSession(phase: currentPhase, duration: currentPhase.duration, date: Date()))
        isActive = false
        stopTimer()
        endTime = nil
        startAlarm()
    }
    
    private func startAlarm() {
        guard !isAlarming else { return }
        isAlarming = true
        
        let soundName = (currentPhase == .work) ? "Glass" : "Bottle"
        
        NSSound(named: soundName)?.play()
        
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            NSSound(named: soundName)?.play()
        }
    }
    
    func skipPhase() {
        stopTimer()
        stopAlarm()
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
        stopAlarm()
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
                
                if self.isActive {
                    self.startTimer()
                }
            }
        }
    }
}
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
    var pulse: Bool = false
    
    var onStateChange: ((Bool) -> Void)?
    
    private var timer: Timer?
    private var collapseTask: Task<Void, Never>?
    
    var progress: Double {
        let total = currentPhase.duration
        return (total - timeRemaining) / total
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
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
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        pulse = false
    }
    
    private func tick() {
        pulse.toggle()
        guard timeRemaining > 0 else {
            completePhase()
            return
        }
        timeRemaining -= 1
    }
    
    private func completePhase() {
        NSSound(named: "Glass")?.play()
        
        isActive = false
        stopTimer()
        skipPhase()
    }
    
    func skipPhase() {
        stopTimer()
        isActive = false
        
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
        } else {
            collapseTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }

                isHovering = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    islandState = .collapsed
                }
                onStateChange?(false)
            }
        }
    }
}
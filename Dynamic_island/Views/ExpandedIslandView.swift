import SwiftUI
import AppKit

struct ExpandedIslandView: View {
    let viewModel: PomodoroViewModel
    var namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 44)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(viewModel.currentPhase == .work ? .red : .green).opacity(0.2))
                    Image(systemName: viewModel.currentPhase == .work ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(viewModel.currentPhase == .work ? .red : .green))
                }
                .frame(width: 32, height: 32)
                .matchedGeometryEffect(id: "icon", in: namespace)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentPhase.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(viewModel.isActive ? "Running" : "Paused")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            Text(viewModel.timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "timer", in: namespace)
            
            HStack(spacing: 30) {
                Button(action: {
                    withAnimation {
                        viewModel.resetTimer()
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation {
                        viewModel.toggleTimer()
                    }
                }) {
                    Image(systemName: viewModel.isAlarming ? "square.fill" : (viewModel.isActive ? "pause.fill" : "play.fill"))
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.isAlarming ? .red : .white)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation {
                        viewModel.skipPhase()
                    }
                }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

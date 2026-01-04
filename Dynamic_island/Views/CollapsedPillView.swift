import SwiftUI

struct CollapsedPillView: View {
    let viewModel: PomodoroViewModel
    var namespace: Namespace.ID

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(viewModel.timeString)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
                
                if viewModel.isActive {
                    StatusDotView(color: viewModel.currentPhase == .work ? .red : .green)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.leading, 12)
            .matchedGeometryEffect(id: "timer", in: namespace)

            Spacer()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusDotView: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
    }
}
import SwiftUI

struct DynamicIslandView: View {
    @Bindable var viewModel: PomodoroViewModel

    @Namespace private var animation

    private var isExpanded: Bool {
        viewModel.isExpanded
    }

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            }

            if isExpanded {
                ExpandedIslandView(
                    viewModel: viewModel,
                    namespace: animation
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    )
                )
            } else {
                CollapsedPillView(
                    viewModel: viewModel,
                    namespace: animation
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    )
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
    }
}

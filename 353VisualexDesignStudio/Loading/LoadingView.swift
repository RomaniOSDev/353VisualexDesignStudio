import SwiftUI

private enum LoadingStyle {
    static let corner: CGFloat = 7
    static let letters = Array("VISUALEX").map(String.init)
    static let slugs = ["A", "V", "T", "o", "W", "A", "L", "T"]
    static let pairValues: [Double] = [-6.0, -4.5, -3.0, -1.5, 0.0, 1.5, -2.5, -5.0]
    static let trackValues: [Double] = [2.0, 1.0, 0.5, -0.5, -1.0, -1.5, -0.5, 1.5]
}

struct LoadingStudioBackdrop: View {
    @State private var glow = false

    var body: some View {
        Color.appBackground
            .overlay {
                Image("BgStudio")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.34)
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.appBackground.opacity(0.92),
                        Color.appBackground.opacity(0.55),
                        Color.appBackground.opacity(0.7),
                        Color.appBackground.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    Rectangle()
                        .fill(Color.appPrimary.opacity(glow ? 0.55 : 0.3))
                        .frame(height: 3)
                        .blur(radius: 6)
                    Rectangle()
                        .fill(Color.appPrimary)
                        .frame(height: 1.5)
                }
                .padding(.bottom, 110)
                .opacity(0.8)
            }
            .overlay(alignment: .bottom) {
                RadialGradient(
                    colors: [Color.appPrimary.opacity(glow ? 0.24 : 0.12), .clear],
                    center: .bottom,
                    startRadius: 10,
                    endRadius: 320
                )
                .frame(height: 320)
            }
            .clipped()
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
    }
}

struct LoadingPlate<Content: View>: View {
    var emphasized: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: LoadingStyle.corner, style: .circular)
                    .stroke(emphasized ? Color.appPrimary : Color.appAccent.opacity(0.38), lineWidth: emphasized ? 1.6 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LoadingStyle.corner, style: .circular))
    }
}

struct LoadingStationCard: View {
    @State private var pulse = false

    var body: some View {
        LoadingPlate(emphasized: true) {
            HStack(alignment: .center, spacing: 16) {
                Text("V")
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundColor(.appPrimary)
                    .shadow(color: Color.appPrimary.opacity(pulse ? 0.7 : 0.25), radius: pulse ? 14 : 6)
                    .frame(width: 72, alignment: .center)

                Rectangle()
                    .fill(Color.appPrimary)
                    .frame(width: 2, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text("VISUALEX")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.appAccent)
                    Text("Design Studio")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appPrimary)
                    Text("Kerning · Presets · Proofs")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.appAccent.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct LoadingKerningBench: View {
    @State private var tight = false
    @State private var activeIndex = 0

    private var activePair: String {
        let letters = LoadingStyle.letters
        let next = min(activeIndex + 1, letters.count - 1)
        return letters[activeIndex] + letters[next]
    }

    private var activeValue: Double {
        LoadingStyle.pairValues[activeIndex % LoadingStyle.pairValues.count]
    }

    private var trackValue: Double {
        LoadingStyle.trackValues[activeIndex % LoadingStyle.trackValues.count]
    }

    var body: some View {
        LoadingPlate {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("KERNING BENCH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.8)
                        .foregroundColor(.appAccent)
                    Spacer()
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(.appBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .circular))
                }

                HStack(spacing: tight ? 1 : 9) {
                    ForEach(Array(LoadingStyle.letters.enumerated()), id: \.offset) { index, letter in
                        let active = index == activeIndex || index == activeIndex + 1
                        Text(letter)
                            .font(.system(size: 30, weight: .semibold, design: .serif))
                            .foregroundColor(active ? .appBackground : .appPrimary)
                            .padding(.horizontal, active ? 2 : 0)
                            .background(active ? Color.appPrimary : Color.clear)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)

                LoadingKerningSlider(tight: tight)

                HStack {
                    Text("\(activePair) \(String(format: "%+.1f", activeValue))")
                    Spacer()
                    Text("TR \(String(format: "%+.1f", trackValue))")
                }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .transaction { $0.animation = nil }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                tight = true
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 520_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    activeIndex = (activeIndex + 1) % (LoadingStyle.letters.count - 1)
                }
            }
        }
    }
}

struct LoadingKerningSlider: View {
    let tight: Bool

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let thumbX = tight ? width * 0.22 : width * 0.78
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appAccent.opacity(0.22))
                    .frame(height: 3)

                Capsule()
                    .fill(Color.appPrimary)
                    .frame(width: thumbX, height: 3)

                ForEach(0..<9, id: \.self) { tick in
                    Rectangle()
                        .fill(Color.appAccent.opacity(tick == 4 ? 0.7 : 0.3))
                        .frame(width: 1, height: tick == 4 ? 12 : 7)
                        .offset(x: width * CGFloat(tick) / 8 - 0.5, y: 10)
                }

                RoundedRectangle(cornerRadius: 3, style: .circular)
                    .fill(Color.appPrimary)
                    .frame(width: 14, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .circular)
                            .stroke(Color.appBackground.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.appPrimary.opacity(0.6), radius: 6)
                    .offset(x: thumbX - 7)
            }
            .frame(height: 20)
        }
        .frame(height: 30)
    }
}

struct LoadingSlugRow: View {
    @State private var filled = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(LoadingStyle.slugs.enumerated()), id: \.offset) { index, mark in
                let lit = index < filled
                Text(mark)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(lit ? .appBackground : .appPrimary.opacity(0.55))
                    .frame(width: 28, height: 26)
                    .background(lit ? Color.appPrimary : Color.appSurface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .circular)
                            .stroke(Color.appAccent.opacity(lit ? 0.7 : 0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                    .scaleEffect(index == filled - 1 ? 1.08 : 1)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 330_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    filled = filled >= LoadingStyle.slugs.count ? 0 : filled + 1
                }
            }
        }
    }
}

struct LoadingStatusLine: View {
    @State private var step = 0

    private let lines = [
        "Setting the type case",
        "Aligning letter pairs",
        "Pulling the first proof"
    ]

    var body: some View {
        Text(lines[step % lines.count].uppercased())
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(1.6)
            .foregroundColor(.appAccent.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .id(step)
            .transition(.opacity)
            .frame(height: 16)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_700_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.32)) {
                        step = (step + 1) % lines.count
                    }
                }
            }
    }
}

struct LoadingView: View {
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LoadingStudioBackdrop()

                if geo.size.width > geo.size.height {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) {
                appeared = true
            }
        }
    }

    private var kicker: some View {
        Text("SPECIMEN")
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(2)
            .foregroundColor(.appPrimary)
            .opacity(appeared ? 1 : 0)
    }

    private var progress: some View {
        VStack(spacing: 14) {
            LoadingSlugRow()
            LoadingStatusLine()
        }
        .opacity(appeared ? 1 : 0)
    }

    private var portraitLayout: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            kicker
            LoadingStationCard()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            LoadingKerningBench()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            progress
                .padding(.top, 12)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var landscapeLayout: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 14) {
                kicker
                LoadingStationCard()
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                progress
                    .padding(.top, 4)
            }
            .frame(maxWidth: 360)

            LoadingKerningBench()
                .frame(maxWidth: 360)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}

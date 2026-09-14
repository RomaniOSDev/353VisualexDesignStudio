import SwiftUI

struct TypeBanner: View {
    let imageName: String
    var kicker: String = ""
    var title: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 118)
                .background {
                    Palette.surface
                        .overlay {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }

            Rectangle()
                .fill(Palette.primary)
                .frame(height: 2)

            if kicker.isEmpty == false || title.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    if kicker.isEmpty == false {
                        Text(kicker)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.8)
                            .foregroundColor(Palette.accent)
                    }
                    if title.isEmpty == false {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Palette.primary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: KerningMath.plateCorner, style: .circular))
        .overlay(
            RoundedRectangle(cornerRadius: KerningMath.plateCorner, style: .circular)
                .stroke(Palette.accent.opacity(0.4), lineWidth: 1)
        )
    }
}

struct MetalSlug: View {
    let mark: String

    var body: some View {
        Text(mark)
            .font(.system(size: 13, weight: .bold, design: .serif))
            .foregroundColor(Palette.background)
            .frame(width: 34, height: 28)
            .background(Palette.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .circular)
                    .stroke(Palette.accent.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
    }
}

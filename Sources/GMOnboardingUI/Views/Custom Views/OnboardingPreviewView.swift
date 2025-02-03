//
//  OnboardingPreviewView.swift
//  GMOnboardingUI
//
//  Created by Mert Serin on 2024-12-03.
//

import Kingfisher
import SwiftUI
import AVFoundation

public struct OnboardingPreviewView: View {

    let backgroundElements: [OnboardingScreenItem]
    let elements: [OnboardingScreenItem]
    let onCtaAction: () -> ()

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                ForEach(backgroundElements) { element in
                    makeItem(element)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                VStack {
                    ForEach(elements) { element in
                        makeItem(element)
                    }
                }
            }
            .cornerRadius(40)
        }
    }

    @ViewBuilder
    private func makeItem(_ element: OnboardingScreenItem) -> some View {
        switch element.type {
        case .spacer:
            Spacer()
        case .text:
            makeText(from: element.item)
        case .image:
            EmptyView()
        case .button:
            makeButton(from: element.item)
        case .video:
            EmptyView()
        case .backgroundView:
            makeBackgroundView(from: element.item)
        case .progress:
            EmptyView()
        case .gradient:
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeText(from item: Any) -> some View {
        if let item = item as? ItemText {
            Text(item.text)
                .foregroundStyle(Color(hex: item.fontColor))
                .font(font(from: item.fontStyle, size: item.fontSize))
                .padding(item.padding.makeEdgeInsets())
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(item.alignment.toTextAlignment())
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeButton(from item: Any) -> some View {
        if let item = item as? ItemButton {
            Button {
                onCtaAction()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text(item.text)
                    .foregroundStyle(Color(hex: item.fontColor))
                    .font(font(from: item.fontStyle, size: item.fontSize))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: item.backgroundColor))
                    .cornerRadius(item.cornerRadius)
            }
            .padding(item.padding.makeEdgeInsets())
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeBackgroundView(from item: Any) -> some View {
        if let item = item as? ItemBackgroundView {
            if item.type == .image {
                if let data = item.data {
                    Image(uiImage: UIImage(data: data) ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    KFImage(URL(string: item.url ?? ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                }
            } else if item.type == .video {
                PlayerUIView(url: item.url ?? "")
                    .id(item.id)
            } else {
                Color(hex: item.backgroundColor).ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            EmptyView()
        }
    }

    private func makeItemImageView(from item: Any) -> some View {
        Group {
            if let item = item as? ItemImage {
                KFImage(URL(string: item.url ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: item.size.width, height: item.size.height)
                    .cornerRadius(item.cornerRadius)
                    .padding(item.padding.makeEdgeInsets())
                    .clipped()
            } else {
                EmptyView()
            }
        }
    }

    private func font(from style: String?, size: CGFloat) -> Font {
        return OnboardingUIManager.shared.configuration.getFont(from: FontStyle(rawValue: style ?? "") ?? .primary, size: size)
    }
}

#Preview {
    OnboardingPreviewView(backgroundElements: [], elements: [], onCtaAction: {
        
    })
}

struct PlayerUIView: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> PlayerView {
        return PlayerView(url: url)
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.update(with: url)
    }
}

class PlayerView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var url: String

    init(url: String) {
        self.url = url

        super.init(frame: .zero)

        playerLayer.player = AVPlayer(url: URL(string: url) ?? URL("test.mp4")!)
        playerLayer.videoGravity = .resizeAspectFill

        playerLayer.player?.actionAtItemEnd = .none
        playerLayer.player?.play()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: playerLayer.player?.currentItem)

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)

        layer.addSublayer(playerLayer)
    }

    func update(with url: String) {
        guard let url = URL(string: url) else { return }
        self.playerLayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: playerLayer.player?.currentItem)

        playerLayer.player?.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        playerLayer.player?.currentItem?.seek(to: .zero, completionHandler: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

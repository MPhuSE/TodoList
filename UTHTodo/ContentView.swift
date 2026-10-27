import SwiftUI
import Combine

// MARK: - Dữ liệu một trang

final class TodoPage: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let buttonTitle: String

    init(
        id: Int,
        title: String,
        detail: String,
        buttonTitle: String
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Dữ liệu ứng dụng

final class TodoData {
    let brandBold = "UTH"
    let brandRegular = "Todo"

    let slogan = "Việc học, việc nhà – gọn gàng mỗi ngày"
    let version = "Phiên bản 2.1.0"
    let skipTitle = "Bỏ qua"

    let studyTitle = "Học tập"
    let lifeTitle = "Cuộc sống"
    let reminder = "Ôn bài Toán lúc 19:00"

    let splashDuration: UInt64 = 2_000_000_000

    let pages: [TodoPage] = [
        TodoPage(
            id: 0,
            title: "Mọi việc, gọn trong một\nchỗ",
            detail: """
            Ghi lại bài tập, việc nhà, lịch hẹn. Không \
            còn quên việc nào.
            """,
            buttonTitle: "Tiếp tục"
        ),

        TodoPage(
            id: 1,
            title: "Chia theo Học tập và\nCuộc sống",
            detail: """
            Mỗi việc có nhóm riêng, nhìn là biết hôm \
            nay cần lo gì.
            """,
            buttonTitle: "Tiếp tục"
        ),

        TodoPage(
            id: 2,
            title: "Nhắc đúng lúc",
            detail: """
            Bật thông báo để UTH Todo nhắc bạn \
            trước hạn chót.
            """,
            buttonTitle: "Bắt đầu ngay"
        )
    ]
}

// MARK: - Màu sắc dùng chung

final class TodoStyle {
    static let blue = Color(
        red: 57.0 / 255,
        green: 85.0 / 255,
        blue: 224.0 / 255
    )

    static let lavender = Color(
        red: 237.0 / 255,
        green: 239.0 / 255,
        blue: 251.0 / 255
    )

    static let grayLine = Color(
        red: 225.0 / 255,
        green: 225.0 / 255,
        blue: 228.0 / 255
    )
}

// MARK: - Quản lý trạng thái và Navigation

@MainActor
final class TodoViewModel: ObservableObject {
    let data = TodoData()

    @Published private(set) var showingSplash = true
    @Published var path: [Int] = []

    func start() async {
        guard showingSplash else { return }

        do {
            try await Task.sleep(
                nanoseconds: data.splashDuration
            )
        } catch {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            showingSplash = false
        }
    }

    func next(from page: TodoPage) {
        if page.id < data.pages.count - 1 {
            path.append(page.id + 1)
        } else {
            backToFirst()
        }
    }

    func skip() {
        // Bỏ qua các bước còn lại để đến trang cuối.
        path = [1, 2]
    }

    func backToFirst() {
        path.removeAll()
    }
}

// MARK: - Màn hình gốc

struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()

    var body: some View {
        Group {
            if viewModel.showingSplash {
                TodoSplashScreen(data: viewModel.data)
            } else {
                NavigationStack(path: $viewModel.path) {
                    TodoIntroScreen(
                        page: viewModel.data.pages[0],
                        viewModel: viewModel
                    )
                    .navigationDestination(for: Int.self) { index in
                        TodoIntroScreen(
                            page: viewModel.data.pages[index],
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden(true)
        .task {
            await viewModel.start()
        }
    }
}

// MARK: - Khung thiết kế theo tỉ lệ ảnh mẫu

struct TodoCanvas<Content: View>: View {
    let background: Color
    let content: Content

    init(
        background: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / 390,
                geometry.size.height / 844
            )

            ZStack(alignment: .topLeading) {
                background

                content
            }
            .frame(width: 390, height: 844)
            .scaleEffect(scale)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .background(background)
        .ignoresSafeArea()
    }
}

// MARK: - Logo checklist giống mẫu

struct TodoMark: View {
    let size: CGFloat
    var splash = false

    private var ink: Color {
        splash ? TodoStyle.blue : .white
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(splash ? Color.white : TodoStyle.blue)

            VStack(alignment: .leading, spacing: size * 0.09) {
                HStack(spacing: size * 0.05) {
                    ZStack {
                        Circle()
                            .fill(ink)

                        Image(systemName: "checkmark")
                            .font(
                                .system(
                                    size: size * 0.10,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                splash ? Color.white : TodoStyle.blue
                            )
                    }
                    .frame(
                        width: size * 0.18,
                        height: size * 0.18
                    )

                    Capsule()
                        .fill(ink)
                        .frame(
                            width: size * 0.32,
                            height: size * 0.075
                        )
                }

                HStack(spacing: size * 0.05) {
                    Circle()
                        .stroke(
                            ink.opacity(0.5),
                            lineWidth: size * 0.035
                        )
                        .frame(
                            width: size * 0.15,
                            height: size * 0.15
                        )
                        .frame(width: size * 0.18)

                    Capsule()
                        .fill(ink.opacity(0.5))
                        .frame(
                            width: size * 0.24,
                            height: size * 0.075
                        )
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tên ứng dụng

struct TodoBrand: View {
    let data: TodoData
    var size: CGFloat = 21
    var splash = false

    var body: some View {
        HStack(spacing: size * 0.16) {
            Text(data.brandBold)
                .fontWeight(.bold)
                .foregroundStyle(
                    splash ? Color.white : Color.black
                )

            Text(data.brandRegular)
                .fontWeight(.regular)
                .foregroundStyle(
                    splash ? Color.white : TodoStyle.blue
                )
        }
        .font(.system(size: size))
    }
}

// MARK: - Màn xanh khi mở ứng dụng

struct TodoSplashScreen: View {
    let data: TodoData

    var body: some View {
        TodoCanvas(background: TodoStyle.blue) {
            VStack(spacing: 22) {
                TodoMark(size: 114, splash: true)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 12,
                        y: 6
                    )

                VStack(spacing: 8) {
                    TodoBrand(
                        data: data,
                        size: 40,
                        splash: true
                    )

                    Text(data.slogan)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 390)
            .offset(y: 275)

            VStack(spacing: 14) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: 118, height: 4)

                    Capsule()
                        .fill(.white)
                        .frame(width: 47, height: 4)
                }

                Text(data.version)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 390)
            .offset(y: 756)
        }
    }
}

// MARK: - Ba màn giới thiệu

struct TodoIntroScreen: View {
    let page: TodoPage

    @ObservedObject var viewModel: TodoViewModel

    var body: some View {
        TodoCanvas {
            header
                .frame(width: 336)
                .offset(x: 27, y: 66)

            TodoArtwork(
                page: page,
                data: viewModel.data
            )
            .offset(x: 85, y: 190)

            VStack(alignment: .leading, spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .lineSpacing(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(page.detail)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        Color.black.opacity(0.56)
                    )
                    .lineSpacing(4)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(width: 336, alignment: .leading)
            .offset(x: 27, y: 540)

            indicators
                .offset(x: 27, y: 715)

            Button {
                viewModel.next(from: page)
            } label: {
                Text(page.buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 336, height: 56)
                    .background(TodoStyle.blue)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 15)
                    )
            }
            .buttonStyle(.plain)
            .offset(x: 27, y: 750)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 9) {
            TodoMark(size: 32)

            TodoBrand(data: viewModel.data)

            Spacer()

            Button(viewModel.data.skipTitle) {
                viewModel.skip()
            }
            .font(.system(size: 14))
            .foregroundStyle(.gray)
            .buttonStyle(.plain)
        }
    }

    private var indicators: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.data.pages) { item in
                Capsule()
                    .fill(
                        item.id == page.id
                            ? TodoStyle.blue
                            : Color.gray.opacity(0.3)
                    )
                    .frame(
                        width: item.id == page.id ? 24 : 7,
                        height: 7
                    )
            }
        }
    }
}

// MARK: - Hình minh họa ba trang

struct TodoArtwork: View {
    let page: TodoPage
    let data: TodoData

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(TodoStyle.lavender)

            switch page.id {
            case 0:
                VStack(spacing: 12) {
                    taskRow(done: true, width: 108)
                    taskRow(done: false, width: 86)
                    taskRow(done: false, width: 116)
                }

            case 1:
                VStack(spacing: 14) {
                    categoryCard(
                        title: data.studyTitle,
                        color: TodoStyle.blue,
                        lineWidth: 136
                    )

                    categoryCard(
                        title: data.lifeTitle,
                        color: Color(
                            red: 0.60,
                            green: 0.39,
                            blue: 0.14
                        ),
                        lineWidth: 108
                    )
                }
                .offset(y: 10)

            default:
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 86, height: 86)
                            .shadow(
                                color: .black.opacity(0.06),
                                radius: 10,
                                y: 5
                            )

                        Image(systemName: "bell")
                            .font(.system(size: 37, weight: .light))
                            .foregroundStyle(TodoStyle.blue)
                    }

                    Text(data.reminder)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 180, height: 40)
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                        .shadow(
                            color: .black.opacity(0.04),
                            radius: 8,
                            y: 5
                        )
                }
                .offset(y: 15)
            }
        }
        .frame(width: 220, height: 260)
    }

    private func taskRow(
        done: Bool,
        width: CGFloat
    ) -> some View {
        HStack(spacing: 12) {
            Image(
                systemName: done
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(.system(size: 22))
            .foregroundStyle(
                done
                    ? TodoStyle.blue
                    : Color.gray.opacity(0.4)
            )

            Capsule()
                .fill(TodoStyle.grayLine)
                .frame(width: width, height: 7)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(width: 200, height: 50)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            y: 5
        )
    }

    private func categoryCard(
        title: String,
        color: Color,
        lineWidth: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.1))
                .clipShape(
                    RoundedRectangle(cornerRadius: 6)
                )

            Capsule()
                .fill(TodoStyle.grayLine)
                .frame(width: lineWidth, height: 7)
        }
        .frame(width: 166, alignment: .leading)
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            y: 5
        )
    }
}

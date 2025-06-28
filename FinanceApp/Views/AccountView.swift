import SwiftUI

struct AccountView: View {
    init() {
        UIScrollView.appearance().decelerationRate = .init(rawValue: 1.5)
    }

    @StateObject private var vm = AccountViewModel()
    @FocusState private var isFocused: Bool
    @AppStorage("spoilerIsOn") private var spoilerIsOn: Bool = true
    @State private var balanceWidth: CGFloat = 0

    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    ScrollView {
                        Color(.systemGray6)
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 0)

                        VStack(spacing: 24) {
                            HStack {
                                Text("💰 Баланс")
                                    .fontWeight(.semibold)
                                Spacer()

                                if vm.isEditing {
                                    HStack(spacing: 4) {
                                        TextField("0.00", text: $vm.balanceText)
                                            .keyboardType(.decimalPad)
                                            .focused($isFocused)
                                            .multilineTextAlignment(.trailing)
                                            .onReceive(vm.$balanceText) { newValue in
                                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                                if filtered != newValue { vm.balanceText = filtered }
                                            }

                                        Button {
                                            vm.pasteBalanceFromClipboard()
                                        } label: {
                                            Image(systemName: "doc.on.clipboard")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } else if let value = Decimal(string: vm.balanceText) {
                                    ZStack(alignment: .trailing) {
                                        Text("\(value, format: .number) \(vm.currency.symbol)")
                                            .opacity(spoilerIsOn ? 0 : 1)
                                            .background(
                                                GeometryReader { geo in
                                                    Color.clear
                                                        .onAppear {
                                                            balanceWidth = geo.size.width
                                                        }
                                                }
                                            )

                                        if spoilerIsOn {
                                            SpoilerView(isOn: true)
                                                .frame(width: balanceWidth, height: 20)
                                        }
                                    }
                                    .onChange(of: vm.balanceText) { _ in
                                        balanceWidth = 0
                                    }
                                } else {
                                    Text("— \(vm.currency.symbol)")
                                }
                            }
                            .padding()
                            .background(vm.isEditing ? Color.white : Color("AccentColor"))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onTapGesture {
                                if vm.isEditing { isFocused = true }
                            }

                            HStack {
                                Text("Валюта")
                                Spacer()
                                Text(vm.currency.symbol)
                                    .foregroundColor(.gray)

                                if vm.isEditing {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(vm.isEditing ? Color.white : Color("AccentColor").opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if vm.isEditing {
                                    vm.showCurrencyPicker = true
                                }
                            }

                            Spacer(minLength: 20)
                        }
                        .padding(.top, 16)
                        .gesture(
                            DragGesture().onChanged { _ in
                                if vm.isEditing {
                                    vm.hideKeyboard()
                                }
                            }
                        )
                    }
                    .background(Color(.systemGray6))
                    .refreshable {
                        await vm.load()
                    }
                    .navigationTitle("Мой счёт")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(vm.isEditing ? "Сохранить" : "Редактировать") {
                                if vm.isEditing {
                                    Task { await vm.save() }
                                } else {
                                    vm.isEditing = true
                                }
                            }
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color("IconColor"))
                        }
                    }

                    currencyPicker
                }
            }

            .overlay(
                ShakeDetectorView()
                    .allowsHitTesting(false)
                    .id(vm.isEditing) // пересоздаём для активации UIResponder
            )
        }

        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            withAnimation {
                spoilerIsOn.toggle()
            }
        }
    }

    // MARK: — Валюта
    @ViewBuilder private var currencyPicker: some View {
        if vm.showCurrencyPicker {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { vm.showCurrencyPicker = false }

            GeometryReader { proxy in
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Text("Валюта")
                            .font(.headline)
                            .padding(.vertical, 16)

                        Divider()

                        ForEach(Currency.allCases) { cur in
                            Button {
                                vm.select(cur)
                                vm.showCurrencyPicker = false
                            } label: {
                                Text(cur.displayName)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color("IconColor"))
                            }

                            if cur != Currency.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .padding(.horizontal, 12)
                    .padding(.bottom, proxy.safeAreaInsets.bottom)
                }
                .ignoresSafeArea()
            }
            .transition(.move(edge: .bottom))
            .animation(.easeOut, value: vm.showCurrencyPicker)
        }
    }
}

// MARK: — Rounded Corner
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(roundedRect: rect,
                         byRoundingCorners: corners,
                         cornerRadii: CGSize(width: radius, height: radius)).cgPath
        )
    }
}

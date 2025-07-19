import SwiftUI

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

extension View {
    func errorAlert(errorWrapper: Binding<ErrorWrapper?>) -> some View {
        self
            .alert(item: errorWrapper) { wrapper in
                Alert(
                    title: Text("Ошибка"),
                    message: Text(wrapper.message),
                    dismissButton: .default(Text("OK")) {
                        errorWrapper.wrappedValue = nil
                    }
                )
            }
    }
}

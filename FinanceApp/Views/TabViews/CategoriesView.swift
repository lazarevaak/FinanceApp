import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGray6)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 8) {
                        // MARK: - Custom Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.gray)
                            
                            TextField("Search", text: $viewModel.searchText)
                                .foregroundColor(Color.gray)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.gray)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color("BackColor").opacity(0.2))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // MARK: - Header
                        Text("СТАТЬИ")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // MARK: - Category List
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredCategories.enumerated()), id: \.element.id) { index, category in
                                HStack(spacing: 12) {
                                    Text(String(category.emoji))
                                        .font(.system(size: 12))
                                        .frame(width: 22, height: 22)
                                        .background(Color.green.opacity(0.2))
                                        .clipShape(Circle())

                                    Text(category.name)
                                        .font(.body)

                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.leading, 18)
                                .padding(.trailing, 16)

                                if index < viewModel.filteredCategories.count - 1 {
                                    Divider()
                                        .padding(.leading, 48)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                }
                .navigationTitle("Мои статьи")
            }
        }
    }
}

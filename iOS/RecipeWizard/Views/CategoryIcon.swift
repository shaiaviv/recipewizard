import SwiftUI

/// Shows the watercolor illustration for a recipe category.
struct CategoryIcon: View {
    let category: RecipeListViewModel.RecipeCategory
    var size: CGFloat = 44

    var body: some View {
        Image(category.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

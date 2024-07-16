import SwiftUI
import Charts

struct BudgetPieChartView: View {
    var categories: [Category]
    var totalBudget: Double
    
    var body: some View {
        Chart {
            ForEach(extendedCategories) { category in
                SectorMark(
                    angle: .value("Budget", category.budget),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(Color(hex: category.color) ?? .blue) // Convert hex to Color, default to Apple blue
            }
        }
        .frame(height: 200)
        .chartLegend(.hidden) // Hide default legend
        .padding(.horizontal)
    }
    
    private var extendedCategories: [Category] {
        var categoriesWithOther = categories
        let categoriesTotalBudget = categories.reduce(0) { $0 + $1.budget }
        let otherBudget = totalBudget - categoriesTotalBudget
        
        if otherBudget > 0 {
            categoriesWithOther.append(Category(name: "Other", color: "blue", budget: otherBudget)) // Use a key for Apple blue
        }
        
        return categoriesWithOther
    }
}


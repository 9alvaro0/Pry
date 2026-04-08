import SwiftUI

extension GraphQLInfo.OperationType {
    var color: Color {
        self == .mutation ? PryTheme.Colors.warning : PryTheme.Colors.syntaxString
    }
}

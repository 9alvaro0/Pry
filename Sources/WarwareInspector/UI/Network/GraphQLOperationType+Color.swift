import SwiftUI

extension GraphQLInfo.OperationType {
    var color: Color {
        self == .mutation ? InspectorTheme.Colors.warning : InspectorTheme.Colors.syntaxString
    }
}

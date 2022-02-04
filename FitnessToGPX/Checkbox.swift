//
//  Checkbox.swift
//  FitnessToGPX
//
//  Created by Sergej Jaskiewicz on 04.02.2022.
//

import SwiftUI

struct Checkbox: View {

    @Binding var checked: Bool

    init(checked: Binding<Bool>) {
        self._checked = checked
    }

    var body: some View {
        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
            .foregroundColor(checked ? Color.accentColor : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

struct CheckBoxView_Previews: PreviewProvider {
    struct CheckBoxViewHolder: View {
        @State var checked = false

        var body: some View {
            Checkbox(checked: $checked)
        }
    }

    static var previews: some View {
        CheckBoxViewHolder()
            .previewLayout(.sizeThatFits)
    }
}

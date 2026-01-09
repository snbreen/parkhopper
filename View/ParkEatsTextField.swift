//
//  ParkEatsTextField.swift
//  ParkEats
//
//  Created by Sam Breen on 12/3/25.
//

import SwiftUI
import UIKit

//snatched the idea straight from lecture but unfortunately it does still have the old app name 
struct ParkEatsTextField: UIViewRepresentable {
    @Binding var text: String
        var placeholder: String
        var isSecure: Bool = false
        var keyboardType: UIKeyboardType = .default
        var textContentType: UITextContentType?
        var returnKeyType: UIReturnKeyType = .default
        var onCommit: (() -> Void)? = nil
        
    //basically just setting all the textfield duties, borrowed most of the func names in this from the code we had in the notes
        func makeUIView(context: Context) -> UITextField {
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.isSecureTextEntry = isSecure
            textField.keyboardType = keyboardType
            textField.textContentType = textContentType
            textField.returnKeyType = returnKeyType
            textField.delegate = context.coordinator
            textField.borderStyle = .roundedRect
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            return textField
        }
        
        //make sure the UI view is updating along with this representable we've got going on
        func updateUIView(_ uiView: UITextField, context: Context) {
            uiView.text = text
        }
        
    //makes the coordinator that keeps all this working
        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, onCommit: onCommit)
        }
        
        final class Coordinator: NSObject, UITextFieldDelegate {
            //binding var for the coordinator to update
            @Binding var text: String
            var onCommit: (() -> Void)?
            
            //custom init
            init(text: Binding<String>, onCommit: (() -> Void)? = nil) {
                self._text = text
                self.onCommit = onCommit
            }
            
            //updates the binding var
            func textFieldDidChangeSelection(_ textField: UITextField) {
                text = textField.text ?? ""
            }
            
            //for when it needs to be free and give up its first responder job
            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                onCommit?()
                textField.resignFirstResponder()
                return true
            }
        }
}

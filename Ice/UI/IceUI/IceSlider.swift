//
//  IceSlider.swift
//  Ice
//

import SwiftUI

/// A system `Slider` with its current value shown as text after the track.
///
/// The readout's width only ever grows. The slider fills whatever the readout leaves, so a
/// readout that shrank and grew with the value ("9 sec" → "10 sec") would resize the track
/// under the pointer mid-drag, and the value at the pointer could flip back and forth.
struct IceSlider<Value: BinaryFloatingPoint, ValueLabel: View>: View where Value.Stride: BinaryFloatingPoint {
    @Binding private var value: Value

    @State private var valueLabelWidth: CGFloat = 0

    private let bounds: ClosedRange<Value>
    private let step: Value?
    private let valueLabel: ValueLabel

    init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value? = nil,
        @ViewBuilder valueLabel: () -> ValueLabel
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.valueLabel = valueLabel()
    }

    /// - Parameter valueLabel: An already-localized label, normally `L("app.…")`. See
    ///   ``IcePicker`` for why this is a `String` and not a `LocalizedStringKey`.
    init(
        _ valueLabel: String,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value? = nil
    ) where ValueLabel == Text {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.valueLabel = Text(valueLabel)
    }

    var body: some View {
        HStack {
            slider
                .labelsHidden()
            valueLabel
                .monospacedDigit()
                .fixedSize()
                .onFrameChange { frame in
                    valueLabelWidth = max(valueLabelWidth, frame.width)
                }
                .frame(minWidth: valueLabelWidth, alignment: .trailing)
                .accessibilityHidden(true) // The slider already carries it as its label.
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let step {
            Slider(value: $value, in: bounds, step: Value.Stride(step)) {
                valueLabel
            }
        } else {
            Slider(value: $value, in: bounds) {
                valueLabel
            }
        }
    }
}

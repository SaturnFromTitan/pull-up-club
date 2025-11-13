import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";

class RepsForm extends StatefulWidget {
  const RepsForm({
    required this.onValidSubmit,
    super.key,
    this.submitText = "Submit",
    this.submitIcon = Icons.check,
    this.submitGradient = AppGradients.secondary,
    this.minValue = 0,
    this.cancelText = "Back",
    this.cancelIcon = Icons.arrow_back,
    this.onCancel,
    this.initialValue,
    this.infoText,
  });
  final String submitText;
  final IconData submitIcon;
  final LinearGradient submitGradient;
  final void Function(int reps) onValidSubmit;
  final int minValue;
  final String cancelText;
  final IconData cancelIcon;
  final VoidCallback? onCancel;
  final int? initialValue;
  final String? infoText;

  @override
  State<RepsForm> createState() => _RepsFormState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("submitText", submitText))
      ..add(DiagnosticsProperty<IconData>("submitIcon", submitIcon))
      ..add(DiagnosticsProperty<LinearGradient?>("submitGradient", submitGradient))
      ..add(
        ObjectFlagProperty<void Function(int reps)>.has("onValidSubmit", onValidSubmit),
      )
      ..add(IntProperty("minValue", minValue))
      ..add(StringProperty("cancelText", cancelText))
      ..add(DiagnosticsProperty<IconData>("cancelIcon", cancelIcon))
      ..add(ObjectFlagProperty<VoidCallback?>.has("onCancel", onCancel))
      ..add(IntProperty("initialValue", initialValue))
      ..add(StringProperty("infoText", infoText));
  }
}

class _RepsFormState extends State<RepsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue?.toString() ?? "");
    if (widget.initialValue != null) {
      _isValid = true;
    }
  }

  void submit() {
    // run logic
    final reps = int.parse(_controller.text);
    widget.onValidSubmit(reps);

    // restore initial state
    _controller.clear();
    setState(() {
      _isValid = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _controller,
            maxLength: 2,
            decoration: InputDecoration(
              hintText: "Tap to enter reps",
              counterText: "",
              errorStyle: const TextStyle(fontSize: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter(RegExp("[0-9]"), allow: true),
            ],
            keyboardType: TextInputType.number,
            onTapOutside: (final event) {
              FocusScope.of(context).unfocus();
            },
            onChanged: (_) {
              final currentIsValid = _formKey.currentState?.validate() ?? false;
              setState(() => _isValid = currentIsValid);
            },
            validator: (final value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              if (int.parse(value) < widget.minValue) {
                return "Must be at least ${widget.minValue}";
              }
              return null;
            },
          ),
          if (widget.infoText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              "(${widget.infoText})",
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            onPressed: _isValid ? submit : null,
            text: widget.submitText,
            icon: widget.submitIcon,
            gradient: widget.submitGradient,
          ),
          if (widget.onCancel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GradientButton(
              onPressed: widget.onCancel,
              text: widget.cancelText,
              icon: widget.cancelIcon,
              gradient: AppGradients.light,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

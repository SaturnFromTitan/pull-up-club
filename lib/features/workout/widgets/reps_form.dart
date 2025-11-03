import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/widgets/gradient_button.dart";

class RepsForm extends StatefulWidget {
  final String submitText;
  final IconData submitIcon;
  final void Function(int reps) onValidSubmit;
  final int minValue;
  final String cancelText;
  final IconData cancelIcon;
  final void Function()? onCancel;
  const RepsForm({
    super.key,
    this.submitText = "Submit",
    this.submitIcon = Icons.check,
    required this.onValidSubmit,
    this.minValue = 0,
    this.cancelText = "Back",
    this.cancelIcon = Icons.arrow_back,
    this.onCancel,
  });

  @override
  State<RepsForm> createState() => _RepsFormState();
}

class _RepsFormState extends State<RepsForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isValid = false;

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
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
              FilteringTextInputFormatter(RegExp(r"[0-9]"), allow: true),
            ],
            keyboardType: TextInputType.number,
            onChanged: (_) {
              final currentIsValid = _formKey.currentState?.validate() ?? false;
              setState(() => _isValid = currentIsValid);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              if (int.parse(value) < widget.minValue) {
                return "Must be at least ${widget.minValue}";
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            onPressed: _isValid ? submit : null,
            text: widget.submitText,
            icon: widget.submitIcon,
            gradient: AppGradients.secondary,
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

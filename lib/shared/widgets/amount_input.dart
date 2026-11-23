import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Input nominal finansial dengan tipografi besar, tabular figures, dan format otomatis Rupiah.
class AmountInput extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<int> onAmountChanged;
  final int initialAmount;
  final String prefix;
  final bool autofocus;
  final TextStyle? style;
  final String? errorText;

  const AmountInput({
    super.key,
    this.controller,
    required this.onAmountChanged,
    this.initialAmount = 0,
    this.prefix = 'Rp ',
    this.autofocus = false,
    this.style,
    this.errorText,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _internalController;
  bool _isInternal = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _internalController = widget.controller!;
    } else {
      _isInternal = true;
      final initialText = widget.initialAmount > 0
          ? CurrencyFormatter.formatRupiah(widget.initialAmount).replaceAll('Rp ', '')
          : '';
      _internalController = TextEditingController(text: initialText);
    }
  }

  @override
  void dispose() {
    if (_isInternal) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value) {
    final cleanDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final intVal = int.tryParse(cleanDigits) ?? 0;

    // Update formatted text with stable cursor
    if (cleanDigits.isEmpty) {
      _internalController.value = const TextEditingValue(text: '');
      widget.onAmountChanged(0);
      return;
    }

    final formatted = CurrencyFormatter.formatRupiah(intVal).replaceAll('Rp ', '');
    if (_internalController.text != formatted) {
      _internalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    widget.onAmountChanged(intVal);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor = isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
    final errorColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.prefix,
              style: (widget.style ?? AppTypography.balanceLarge).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _internalController,
                keyboardType: TextInputType.number,
                autofocus: widget.autofocus,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: (widget.style ?? AppTypography.balanceLarge).copyWith(
                  color: primaryColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: (widget.style ?? AppTypography.balanceLarge).copyWith(
                    color: hintColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                onChanged: _onTextChanged,
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 1.0,
          color: widget.errorText != null
              ? errorColor
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.errorText!,
              style: AppTypography.caption2.copyWith(color: errorColor),
            ),
          ),
      ],
    );
  }
}

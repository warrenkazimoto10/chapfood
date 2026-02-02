import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';

class ValidationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;

  const ValidationField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<ValidationField> createState() => _ValidationFieldState();
}

class _ValidationFieldState extends State<ValidationField> {
  bool _isPasswordVisible = false;
  String? _errorText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec indicateur obligatoire
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 16,
                color: AppColors.getTextColor(context),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTextStyles.loginSubtitle.copyWith(
                color: AppColors.getTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Champ de saisie
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _hasFocus = hasFocus;
            });
            if (!hasFocus) {
              _validate();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorText != null
                    ? Colors.red
                    : _hasFocus
                        ? AppColors.getPrimaryColor(context)
                        : AppColors.getBorderColor(context),
                width: _errorText != null || _hasFocus ? 2 : 1,
              ),
              color: widget.enabled
                  ? AppColors.getCardColor(context)
                  : AppColors.getCardColor(context).withOpacity(0.5),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword && !_isPasswordVisible,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              style: TextStyle(
                color: AppColors.getTextColor(context),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),
          ),
        ),
        
        // Message d'erreur
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Widget pour afficher les règles de validation
class ValidationRules extends StatelessWidget {
  final List<String> rules;
  final List<bool> fulfilled;

  const ValidationRules({
    super.key,
    required this.rules,
    required this.fulfilled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.asMap().entries.map((entry) {
        final index = entry.key;
        final rule = entry.value;
        final isFulfilled = index < fulfilled.length ? fulfilled[index] : false;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                isFulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isFulfilled ? Colors.green : AppColors.getSecondaryTextColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule,
                  style: TextStyle(
                    color: isFulfilled 
                        ? Colors.green 
                        : AppColors.getSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: isFulfilled ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

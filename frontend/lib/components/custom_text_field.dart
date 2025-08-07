// lib/components/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool hasError;
  final String? errorText;
  final bool enabled;
  final Widget? suffixIcon;
  final List<String>? options; // Para dropdowns
  final Function(String)? onOptionSelected;
  final bool isDropdown;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hasError = false,
    this.errorText,
    this.enabled = true,
    this.suffixIcon,
    this.options,
    this.onOptionSelected,
    this.isDropdown = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _showDropdown = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isDropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.enabled ? () {
              setState(() {
                _showDropdown = !_showDropdown;
              });
            } : null,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.hasError 
                    ? Colors.red 
                    : widget.enabled 
                      ? const Color(0xFF012345) 
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
                color: widget.enabled ? Colors.white : Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.controller?.text.isEmpty ?? true 
                      ? widget.hintText 
                      : widget.controller!.text,
                    style: TextStyle(
                      color: widget.controller?.text.isEmpty ?? true 
                        ? Colors.grey.shade600 
                        : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    _showDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_showDropdown && widget.enabled && widget.options != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options!.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      widget.controller?.text = widget.options![index];
                      widget.onOptionSelected?.call(widget.options![index]);
                      setState(() {
                        _showDropdown = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: index < widget.options!.length - 1 ? 1 : 0,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.options![index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.hasError && widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.hasError ? Colors.red : const Color(0xFF012345),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.hasError ? Colors.red : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.hasError ? Colors.red : const Color(0xFF012345),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
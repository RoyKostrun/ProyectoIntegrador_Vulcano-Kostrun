// lib/components/account_type_selector.dart
import 'package:flutter/material.dart';

class AccountTypeSelector extends StatelessWidget {
  final bool isPersonalSelected;
  final bool isEmpresarialSelected;
  final Function(bool) onSelectionChanged;

  const AccountTypeSelector({
    Key? key,
    required this.isPersonalSelected,
    required this.isEmpresarialSelected,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccountTypeButton(
            text: 'Personal',
            isSelected: isPersonalSelected,
            onTap: () => onSelectionChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccountTypeButton(
            text: 'Empresarial',
            isSelected: isEmpresarialSelected,
            onTap: () => onSelectionChanged(false),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
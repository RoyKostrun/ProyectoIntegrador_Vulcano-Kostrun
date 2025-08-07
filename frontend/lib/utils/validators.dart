// lib/utils/validators.dart
class Validators {
  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Campo obligatorio*';
    
    // Solo letras, espacios, acentos y ñ
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegex.hasMatch(name.trim())) {
      return 'Solo se permiten letras';
    }
    
    if (name.trim().length < 2) {
      return 'Mínimo 2 caracteres';
    }
    
    return null;
  }

  static String? validateStreet(String street) {
    if (street.trim().isEmpty) return 'Campo obligatorio*';
    
    // Letras, números, espacios, acentos, ñ y algunos caracteres especiales comunes en direcciones
    final streetRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\.\-°]+$');
    if (!streetRegex.hasMatch(street.trim())) {
      return 'Formato de calle inválido';
    }
    
    if (street.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    
    return null;
  }

  static String? validateDNI(String dni) {
    if (dni.trim().isEmpty) return 'Campo obligatorio*';
    
    // Solo números, entre 7 y 8 dígitos
    final dniRegex = RegExp(r'^[0-9]{7,8}$');
    if (!dniRegex.hasMatch(dni.trim())) {
      return 'DNI debe tener 7 u 8 números';
    }
    
    return null;
  }

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'Campo obligatorio*';
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Email inválido';
    }
    
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Campo obligatorio*';
    
    if (password.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Campo obligatorio*';
    
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  static String? validatePhone(String phone) {
    if (phone.trim().isEmpty) return 'Campo obligatorio*';
    
    // Números, espacios, guiones, paréntesis y el símbolo +
    final phoneRegex = RegExp(r'^[\d\s\-$$$$\+]+$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return 'Formato de teléfono inválido';
    }
    
    if (phone.replaceAll(RegExp(r'[\s\-$$$$\+]'), '').length < 8) {
      return 'Teléfono muy corto';
    }
    
    return null;
  }

  static String? validateBirthDate(String date) {
    if (date.trim().isEmpty) return 'Campo obligatorio*';
    
    try {
      final birthDate = DateTime.parse(date);
      final today = DateTime.now();
      
      // Calcular edad exacta
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      
      if (birthDate.isAfter(today)) {
        return 'La fecha no puede ser futura';
      }
      
      if (age < 18) { // ← Cambiar de 16 a 18 años
        return 'Debes ser mayor de 18 años';
      }
      
      if (age > 100) {
        return 'Fecha inválida';
      }
      
      return null;
    } catch (e) {
      return 'Fecha inválida';
    }
  }
  
  static String? validateRequired(String value, [String fieldName = 'Campo']) {
    if (value.trim().isEmpty) return '$fieldName obligatorio*';
    return null;
  }
}
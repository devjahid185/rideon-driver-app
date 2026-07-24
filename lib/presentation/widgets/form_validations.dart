import 'package:flutter/cupertino.dart';

String? validateEmail(String value, BuildContext context) {
  if (value.isEmpty ||
      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

bool isValidName(String value) {
  if (value.isEmpty) {
    return false;
  }
  if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
    return false;
  }
  return true;
}

String? validatePassword(String value, BuildContext context) {
  // print(value);
  if (value.isEmpty) {
    return 'Please enter valid Password';
  }

  return null;
}

class ValidationService {
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  static bool isNotEmpty(String value) {
    return value.isNotEmpty;
  }

  static void validateAndNavigate(
      {final String? title,
      final String? description,
      final Function(String)? showErrorToastMessage,
      final Function()? navigateToNextScreen,
      BuildContext? context}) {
    if (title.toString() == "") {
      showErrorToastMessage!("The items name field is required");
      return;
    }
    if (description.toString() == "") {
      showErrorToastMessage!("The description field is required");
      return;
    }

    navigateToNextScreen!();
  }
}

//for password caluclate-----------
class PasswordStrengthResult {
  final double strengthPercentage;
  final bool isStrong;

  PasswordStrengthResult(this.strengthPercentage, this.isStrong);
}

PasswordStrengthResult calculatePasswordStrength(String password) {
  // Define rules for password strength
  int minLength = 8;

  // Initialize scores and counters
  int totalScore = 0;
  int lengthScore = 0;
  int upperCaseScore = 0;
  int lowerCaseScore = 0;
  int digitsScore = 0;
  int specialCharsScore = 0;

  // Score based on length
  if (password.length >= minLength) {
    lengthScore = 1;
  }

  // Score based on upper case characters
  RegExp upperCaseRegex = RegExp(r'[A-Z]');
  if (upperCaseRegex.hasMatch(password)) {
    upperCaseScore = 1;
  }

  // Score based on lower case characters
  RegExp lowerCaseRegex = RegExp(r'[a-z]');
  if (lowerCaseRegex.hasMatch(password)) {
    lowerCaseScore = 1;
  }

  // Score based on digits
  RegExp digitsRegex = RegExp(r'\d');
  if (digitsRegex.hasMatch(password)) {
    digitsScore = 1;
  }

  // Score based on special characters
  RegExp specialCharsRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  if (specialCharsRegex.hasMatch(password)) {
    specialCharsScore = 1;
  }

  // Calculate total score
  totalScore = lengthScore +
      upperCaseScore +
      lowerCaseScore +
      digitsScore +
      specialCharsScore;

  // Calculate strength percentage
  double strengthPercentage =
      (totalScore / 5) * 100; // Assuming 5 rules in total

  // Check if password is strong
  bool isStrong = strengthPercentage >=
      80; // You can adjust this threshold according to your requirements

  return PasswordStrengthResult(strengthPercentage, isStrong);
}

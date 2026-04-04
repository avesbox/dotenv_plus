/// A converter class that provides methods to convert string values to their appropriate types (null, boolean, number, or string).
class Converter {
  static final _numberRegex = RegExp(r'^-?\d+(\.\d+)?$');

  static final _booleanTrueRegex = RegExp(
    r'^(true|1|yes|on)$',
    caseSensitive: false,
  );

  static final _booleanFalseRegex = RegExp(
    r'^(false|0|no|off)$',
    caseSensitive: false,
  );

  static final _nullRegex = RegExp(r'^(null|none|nil)$', caseSensitive: false);

  /// A constant constructor for the Converter class, allowing it to be used as a compile-time constant.
  const Converter();

  /// Converts a string value to its appropriate type (null, boolean, number, or string).
  Object? convertValue(Object? value) {
    if (value is! String) {
      return value; // Return non-string values as-is
    }
    if (_nullRegex.hasMatch(value)) {
      return null;
    } else if (_booleanTrueRegex.hasMatch(value)) {
      return true;
    } else if (_booleanFalseRegex.hasMatch(value)) {
      return false;
    } else if (_numberRegex.hasMatch(value)) {
      return num.parse(value);
    }
    return value;
  }
}

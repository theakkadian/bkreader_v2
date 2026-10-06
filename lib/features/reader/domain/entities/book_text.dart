import 'package:equatable/equatable.dart';

/// Split result of a remote text file.
class BookText extends Equatable {
  const BookText({
    required this.syriacText,
    this.companionText = '',
    this.isOnlySyriac = true,
  });

  final String syriacText;
  final String companionText;
  final bool isOnlySyriac;

  @override
  List<Object?> get props => [syriacText, companionText, isOnlySyriac];
}

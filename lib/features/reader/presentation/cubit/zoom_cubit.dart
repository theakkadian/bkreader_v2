import 'package:flutter_bloc/flutter_bloc.dart';

/// Simple zoom overlay flag for InteractiveViewer glue.
class ZoomCubit extends Cubit<bool> {
  ZoomCubit() : super(false);

  void setZoomed(bool value) => emit(value);
}

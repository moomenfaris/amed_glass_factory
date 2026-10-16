import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_images.dart';
import '../data/repositories/movement_images_repository.dart';

final movementImagesRepositoryProvider = Provider<MovementImagesRepository>(
  (_) => ApiMovementImagesRepository(),
);

final movementImagesProvider = FutureProvider.family<MovementImages, int>((
  ref,
  invoiceId,
) {
  return ref.watch(movementImagesRepositoryProvider).fetch(invoiceId);
});

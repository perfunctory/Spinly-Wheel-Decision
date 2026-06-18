import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/models/wheel_template.dart';
import 'package:lucky_wheel/services/storage_service.dart';

/// Immutable state for the wheel.
class WheelState {
  const WheelState({
    required this.options,
    this.isSpinning = false,
    this.selectedIndex,
    this.rotation = 0.0,
    this.activeTemplateId,
    this.spinCount = 0,
    this.wheelType = WheelType.custom,
  });

  final List<String> options;
  final bool isSpinning;
  final int? selectedIndex;
  final double rotation;
  final String? activeTemplateId;
  final int spinCount;
  final WheelType wheelType;

  String? get selectedOption {
    if (selectedIndex == null) return null;
    if (selectedIndex! < 0 || selectedIndex! >= options.length) return null;
    return options[selectedIndex!];
  }

  WheelState copyWith({
    List<String>? options,
    bool? isSpinning,
    int? selectedIndex,
    double? rotation,
    String? activeTemplateId,
    int? spinCount,
    WheelType? wheelType,
    bool clearSelected = false,
  }) {
    return WheelState(
      options: options ?? this.options,
      isSpinning: isSpinning ?? this.isSpinning,
      selectedIndex:
          clearSelected ? null : (selectedIndex ?? this.selectedIndex),
      rotation: rotation ?? this.rotation,
      activeTemplateId:
          clearSelected ? null : (activeTemplateId ?? this.activeTemplateId),
      spinCount: spinCount ?? this.spinCount,
      wheelType: wheelType ?? this.wheelType,
    );
  }
}

/// Provider for the storage service (initialized once at app start).
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden at app start');
});

/// The wheel state notifier — owns all wheel logic, aware of [WheelType].
class WheelNotifier extends StateNotifier<WheelState> {
  WheelNotifier(this._storage, {WheelType type = WheelType.custom})
      : super(
          WheelState(
            options: _storage.loadOptionsForType(type),
            activeTemplateId: _storage.loadActiveTemplateId(),
            wheelType: type,
          ),
        );

  final StorageService _storage;

  // ─── Type switching ───────────────────────────────────────────────

  /// Switch the wheel to a different [type], loading its option set.
  void switchType(WheelType type) {
    if (type == state.wheelType) return;
    state = WheelState(
      options: _storage.loadOptionsForType(type),
      wheelType: type,
      spinCount: state.spinCount,
    );
  }

  // ─── Option Management ────────────────────────────────────────────

  /// Adds a new option. Returns an error message if validation fails.
  String? addOption(String option) {
    final trimmed = option.trim();
    if (trimmed.isEmpty) return 'Option cannot be empty';
    if (state.options.length >= AppConfig.maxOptions) {
      return 'Maximum ${AppConfig.maxOptions} options reached';
    }

    final newOptions = [...state.options, trimmed];
    unawaited(_storage.saveOptionsForType(state.wheelType, newOptions));
    state = state.copyWith(options: newOptions, clearSelected: true);
    return null;
  }

  /// Removes an option by index. Returns an error message if validation fails.
  String? removeOption(int index) {
    if (index < 0 || index >= state.options.length) return 'Invalid option';
    if (state.options.length <= AppConfig.minOptions) {
      return 'Need at least ${AppConfig.minOptions} options';
    }

    final newOptions = [...state.options]..removeAt(index);
    unawaited(_storage.saveOptionsForType(state.wheelType, newOptions));
    state = state.copyWith(options: newOptions, clearSelected: true);
    return null;
  }

  // ─── Spin Logic ───────────────────────────────────────────────────

  /// Computes the exact final rotation so that sector [targetIndex]
  /// lands under the pointer (▲ at top = -π/2 in canvas).
  ///
  /// Used by v3 state engine which pre-selects the index via weighted random.
  double prepareSpinForIndex(int targetIndex) {
    if (state.options.length < AppConfig.minOptions) return state.rotation;
    if (state.isSpinning) return state.rotation;

    final count = state.options.length;
    final sectorAngle = 2 * pi / count;

    // Random sub-sector offset to avoid landing on the exact edge line
    final random = Random();
    final offset = (random.nextDouble() - 0.5) * sectorAngle * 0.8;

    // Compute exact landing rotation
    final desiredModulo =
        -pi / 2 - targetIndex * sectorAngle - sectorAngle / 2 + offset;

    // Normalize into [0, 2π)
    final normalizedTarget =
        ((desiredModulo % (2 * pi)) + 2 * pi) % (2 * pi);

    // Add base rotations on top of current rotation
    final minTotal = state.rotation + AppConfig.baseRotations * 2 * pi;
    final diff = minTotal - normalizedTarget;
    final extraRotations = diff > 0 ? (diff / (2 * pi)).ceil() : 0;
    final newRotation = normalizedTarget + extraRotations * 2 * pi;

    final newSpinCount = state.spinCount + 1;

    state = state.copyWith(
      isSpinning: true,
      rotation: newRotation,
      selectedIndex: targetIndex,
      spinCount: newSpinCount,
      clearSelected: false,
    );

    return newRotation;
  }

  /// Generates a random index and computes the exact final rotation so that
  /// sector [targetIndex] lands under the pointer (▲ at top = -π/2 in canvas).
  ///
  /// Legacy entry point — uses uniform random. v3 should prefer
  /// [prepareSpinForIndex] with a [GameStateNotifier.weightedWheelIndex] call.
  double prepareSpin() {
    if (state.options.length < AppConfig.minOptions) return state.rotation;
    if (state.isSpinning) return state.rotation;

    final random = Random();
    final count = state.options.length;
    final targetIndex = random.nextInt(count);
    final sectorAngle = 2 * pi / count;

    // Random sub-sector offset to avoid landing on the exact edge line
    final offset = (random.nextDouble() - 0.5) * sectorAngle * 0.8;

    // ── Compute exact landing rotation ──────────────────────────
    // Desired R (mod 2π) so sector targetIndex aligns with pointer:
    //   R + targetIndex×α + α/2  =  -π/2  →  R = -π/2 - targetIndex×α - α/2
    final desiredModulo =
        -pi / 2 - targetIndex * sectorAngle - sectorAngle / 2 + offset;

    // Normalize into [0, 2π)
    final normalizedTarget =
        ((desiredModulo % (2 * pi)) + 2 * pi) % (2 * pi);

    // Add base rotations on top of current rotation
    final minTotal = state.rotation + AppConfig.baseRotations * 2 * pi;
    final diff = minTotal - normalizedTarget;
    final extraRotations = diff > 0 ? (diff / (2 * pi)).ceil() : 0;
    final newRotation = normalizedTarget + extraRotations * 2 * pi;

    final newSpinCount = state.spinCount + 1;

    state = state.copyWith(
      isSpinning: true,
      rotation: newRotation,
      selectedIndex: targetIndex,
      spinCount: newSpinCount,
      clearSelected: false,
    );

    return newRotation;
  }

  /// Called when the spin animation completes.
  void onSpinComplete() {
    state = state.copyWith(isSpinning: false);
  }

  /// Resets the result so the user can spin again.
  void resetResult() {
    state = state.copyWith(clearSelected: true);
  }

  // ─── Template ─────────────────────────────────────────────────────

  /// Applies a template, replacing all current options.
  void applyTemplate(WheelTemplate template) {
    final newOptions = List<String>.unmodifiable(template.options);
    unawaited(_storage.saveOptionsForType(state.wheelType, newOptions));
    unawaited(_storage.saveActiveTemplateId(template.id));

    state = WheelState(
      options: newOptions,
      activeTemplateId: template.id,
      spinCount: state.spinCount,
      wheelType: state.wheelType,
    );
  }

  // ─── Should show interstitial ─────────────────────────────────────

  bool get shouldShowInterstitial =>
      state.spinCount > 0 &&
      state.spinCount % AppConfig.spinsPerInterstitial == 0;
}

/// The main wheel provider.
final wheelProvider =
    StateNotifierProvider<WheelNotifier, WheelState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WheelNotifier(storage);
});

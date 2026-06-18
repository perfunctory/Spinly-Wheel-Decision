import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/core/constants/app_strings.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';

/// Page for adding and removing wheel options — aware of [WheelType].
class EditWheelPage extends ConsumerStatefulWidget {
  const EditWheelPage({super.key});

  @override
  ConsumerState<EditWheelPage> createState() => _EditWheelPageState();
}

class _EditWheelPageState extends ConsumerState<EditWheelPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  WheelType _type = WheelType.custom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final type = _parseType(args);
    if (type != _type) {
      _type = type;
      ref.read(wheelProvider.notifier).switchType(type);
    }
  }

  WheelType _parseType(dynamic args) {
    if (args is WheelType) return args;
    if (args is String) {
      return WheelType.values.firstWhere(
        (t) => t.name == args,
        orElse: () => WheelType.custom,
      );
    }
    return WheelType.custom;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _textController.text;
    final error = ref.read(wheelProvider.notifier).addOption(text);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  void _removeOption(int index) {
    final error = ref.read(wheelProvider.notifier).removeOption(index);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(wheelProvider.select((s) => s.options));
    final isAtMax = options.length >= AppConfig.maxOptions;
    final isAtMin = options.length <= AppConfig.minOptions;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_type.emoji} Edit ${_type.label}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: AppStrings.addOptionHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      enabled: !isAtMax,
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: isAtMax ? null : _addOption,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(AppStrings.add),
                  ),
                ],
              ),
            ),

            // Limit indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '${options.length} / ${AppConfig.maxOptions} options',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: isAtMax
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  const Spacer(),
                  if (isAtMax)
                    Text(
                      'Max reached',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Options list
            Expanded(
              child: options.isEmpty
                  ? Center(
                      child: Text(
                        'No options yet.\nTap + to add one!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return _OptionTile(
                          label: options[index],
                          index: index,
                          canDelete: !isAtMin,
                          onDelete: () => _removeOption(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single option row in the edit list.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  final String label;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${label}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      confirmDismiss: (direction) async {
        if (!canDelete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Need at least 2 options'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close,
            size: 20,
            color: canDelete
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7)
                : Theme.of(context).disabledColor,
          ),
          onPressed: canDelete ? onDelete : null,
          tooltip: canDelete ? 'Remove' : 'Cannot remove',
        ),
      ),
    );
  }
}

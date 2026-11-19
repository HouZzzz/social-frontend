import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../models/post.dart';
import '../viewmodels/compose_viewmodel.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageSource source) async {
    final viewModel = context.read<ComposeViewModel>();
    final outcome = await viewModel.pickImage(source);

    if (!mounted) return;
    if (outcome.error != null) {
      _showMessage(outcome.error!);
    }
  }

  Future<void> _showPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final viewModel = context.read<ComposeViewModel>();
    final post = await viewModel.submit();

    if (!mounted) return;

    if (post != null) {
      Navigator.of(context).pop<Post>(post);
    } else if (viewModel.errorMessage.isNotEmpty) {
      _showMessage(viewModel.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ComposeViewModel>();
    final theme = Theme.of(context);
    final content = viewModel.content;
    final error = Validators.postContent(content);
    final remaining = Validators.remainingPostChars(content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пост'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: viewModel.canSubmit ? _submit : null,
              child: viewModel.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Опубликовать'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            onChanged: viewModel.updateContent,
            autofocus: true,
            maxLines: 8,
            minLines: 4,
            maxLength: Validators.maxPostLength,
            decoration: InputDecoration(
              hintText: 'Что нового?',
              border: const OutlineInputBorder(),
              // Свой счётчик вместо стандартного: показываем остаток,
              // а не превышение, и подсвечиваем, когда он кончился.
              counterText: '',
              errorText: content.isEmpty ? null : error,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: remaining < 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: remaining < 0 ? FontWeight.bold : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (viewModel.previewBytes != null)
            _ImagePreview(
              bytes: viewModel.previewBytes!,
              onRemove: viewModel.removeImage,
            )
          else
            OutlinedButton.icon(
              onPressed: viewModel.isBusy ? null : _showPickerSheet,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Прикрепить фото'),
            ),
          const SizedBox(height: 20),
          if (viewModel.isBusy)
            Text(
              viewModel.status == ComposeStatus.uploading
                  ? 'Загружаем изображение…'
                  : 'Публикуем…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Убрать фото',
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../data/repositories/post_repository.dart';
import '../../models/post.dart';

/// состояние экрана создания поста.
enum ComposeStatus { idle, uploading, submitting, success, error }

class PickOutcome {
  const PickOutcome({this.file, this.error});

  final XFile? file;
  final String? error;

  bool get isCancelled => file == null && error == null;
  bool get hasFile => file != null;
}

class ComposeViewModel extends ChangeNotifier {
  ComposeViewModel({
    required PostRepository postRepository,
    ImagePicker? imagePicker,
  })  : _posts = postRepository,
        _picker = imagePicker ?? ImagePicker();

  final PostRepository _posts;
  final ImagePicker _picker;

  ComposeStatus _status = ComposeStatus.idle;
  String _error = '';
  String _content = '';
  XFile? _pickedImage;
  Uint8List? _previewBytes;

  ComposeStatus get status => _status;
  String get errorMessage => _error;
  String get content => _content;
  XFile? get pickedImage => _pickedImage;
  Uint8List? get previewBytes => _previewBytes;
  bool get isBusy =>
      _status == ComposeStatus.uploading || _status == ComposeStatus.submitting;
  bool get canSubmit => _content.trim().isNotEmpty && !isBusy;

  void updateContent(String value) {
    _content = value;
    if (_status == ComposeStatus.error) {
      _status = ComposeStatus.idle;
      _error = '';
    }
    notifyListeners();
  }

  Future<PickOutcome> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );

      if (file == null) {
        return const PickOutcome(); // пользователь закрыл выбор
      }

      _pickedImage = file;
      _previewBytes = await file.readAsBytes();
      notifyListeners();

      AppLogger.info('Выбрано изображение: ${file.mimeType ?? 'unknown'}');
      return PickOutcome(file: file);
    } on PlatformException catch (e) {
      final denied = _isPermissionDenied(e.code);
      AppLogger.warn('image_picker: ${e.code}');

      return PickOutcome(
        error: denied
            ? 'Доступ запрещен, фото не будет прикреплено'
            : 'Не удалось получить фото. Попробуйте ещё раз',
      );
    } catch (e) {
      AppLogger.error('Ошибка выбора изображения', e);
      return const PickOutcome(
        error: 'Не удалось получить фото. Попробуйте ещё раз',
      );
    }
  }

  bool _isPermissionDenied(String code) {
    const deniedCodes = {
      'camera_access_denied',
      'photo_access_denied',
      'access_denied',
      'permission_denied',
    };
    return deniedCodes.contains(code);
  }

  void removeImage() {
    _pickedImage = null;
    _previewBytes = null;
    notifyListeners();
  }

  Future<Post?> submit() async {
    if (_status == ComposeStatus.submitting) return null;

    final trimmed = _content.trim();
    if (trimmed.isEmpty) {
      _status = ComposeStatus.error;
      _error = 'Текст поста не может быть пустым';
      notifyListeners();
      return null;
    }

    try {
      String? imageKey;

      final image = _pickedImage;
      if (image != null) {
        _status = ComposeStatus.uploading;
        notifyListeners();

        final bytes = _previewBytes ?? await image.readAsBytes();
        final contentType = _contentTypeFor(image);

        final presigned = await _posts.presignImage(contentType);
        await _posts.uploadImage(presigned.uploadUrl, bytes, contentType);
        imageKey = presigned.objectKey;

        AppLogger.info('Изображение загружено');
      }

      _status = ComposeStatus.submitting;
      notifyListeners();

      final post = await _posts.createPost(content: trimmed, imageKey: imageKey);
      _status = ComposeStatus.success;

      AppLogger.info('Пост опубликован id=${post.id}');
      notifyListeners();
      return post;
    } on ApiException catch (e) {
      _status = ComposeStatus.error;
      _error = e.message;
      AppLogger.warn('Не удалось опубликовать пост: ${e.message}');
      notifyListeners();
      return null;
    } catch (e) {
      _status = ComposeStatus.error;
      _error = 'Не удалось опубликовать пост';
      AppLogger.error('Неожиданная ошибка публикации', e);
      notifyListeners();
      return null;
    }
  }

  String _contentTypeFor(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime == 'image/png' || mime == 'image/webp') return mime!;

    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

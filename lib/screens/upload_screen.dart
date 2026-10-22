import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../utils/file_picker.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/status_chip.dart';

/// State of a classification request.
///
/// ```
/// IDLE ──▶ LOADING ──┬──▶ SUCCESS
///                    ├──▶ EMPTY
///                    └──▶ ERROR ──▶ RETRY (──▶ LOADING)
/// ```
enum ClassifyStatus { idle, loading, success, empty, error }

class UploadScreen extends StatefulWidget {
  /// Optional photo to start with (also used by widget tests, which cannot
  /// open the platform file picker).
  final PickedFile? initialFile;

  const UploadScreen({super.key, this.initialFile});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PickedFile? _file;
  String? _fileError;
  String? _errorMessage;

  ClassifyStatus _status = ClassifyStatus.idle;

  bool get _loading => _status == ClassifyStatus.loading;

  @override
  void initState() {
    super.initState();
    _file = widget.initialFile;
  }

  /// Picking a new photo always returns the flow to IDLE.
  Future<void> _pick() async {
    if (_loading) return;
    final f = await pickImageFile();
    if (f == null) return;
    setState(() {
      _status = ClassifyStatus.idle;
      _errorMessage = null;
      if (!f.isJpegOrPng) {
        _file = null;
        _fileError = 'Choose a JPEG or PNG photo.';
      } else if (f.size > 5 * 1024 * 1024) {
        _file = null;
        _fileError = 'File is too large (max 5 MB).';
      } else {
        _file = f;
        _fileError = null;
      }
    });
  }

  /// IDLE / EMPTY / ERROR ──▶ LOADING ──▶ SUCCESS | EMPTY | ERROR
  Future<void> _classify() async {
    if (_loading) return;
    if (_file == null) {
      setState(() => _fileError = 'Select a photo first.');
      return;
    }
    setState(() {
      _status = ClassifyStatus.loading;
      _fileError = null;
      _errorMessage = null;
    });
    try {
      final prediction = await DataStore.instance.classifyImage(_file!.name);
      if (!mounted) return;
      if (prediction == null) {
        // EMPTY: the model found no coconut in the photo.
        setState(() => _status = ClassifyStatus.empty);
        return;
      }
      // SUCCESS: open the result screen.
      setState(() => _status = ClassifyStatus.success);
      Navigator.pushReplacementNamed(context, '/classify/result/${prediction.id}');
    } catch (e) {
      final msg = e.toString();
      String message = 'Classification service unavailable. Try again.';
      if (msg.contains('415')) {
        message = 'Choose a JPEG or PNG photo.';
      } else if (msg.contains('413')) {
        message = 'File is too large (max 5 MB).';
      } else if (msg.contains('400')) {
        message = 'The image could not be read.';
      } else if (msg.contains('422')) {
        message = 'Select a photo first.';
      }
      if (!mounted) return;
      setState(() {
        _status = ClassifyStatus.error;
        _errorMessage = message;
      });
    }
  }

  /// ERROR ──▶ RETRY (──▶ LOADING)
  void _retry() => _classify();

  void _remove() => setState(() {
        _file = null;
        _fileError = null;
        _errorMessage = null;
        _status = ClassifyStatus.idle;
      });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final twoCol = width >= 1024;
    return AppShell(
      currentRoute: '/classify',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Classify a coconut',
                          style: Theme.of(context).textTheme.headlineLarge),
                    ),
                    _statusChip(),
                  ],
                ),
                const SizedBox(height: 16),
                if (_status == ClassifyStatus.error) ...[
                  FeedbackBanner(
                    type: FeedbackType.error,
                    message: _errorMessage!,
                    onRetry: _retry,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_status == ClassifyStatus.empty) ...[
                  _emptyPanel(),
                  const SizedBox(height: 12),
                ],
                if (twoCol)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _uploadColumn()),
                      const SizedBox(width: 24),
                      Expanded(child: _tipsCard()),
                    ],
                  )
                else ...[
                  _uploadColumn(),
                  const SizedBox(height: 16),
                  _tipsCard(),
                ],
              ],
            ),
          ),
          if (_loading) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _statusChip() {
    switch (_status) {
      case ClassifyStatus.idle:
        return const StatusChip(label: 'Ready', icon: Icons.image_outlined);
      case ClassifyStatus.loading:
        return const StatusChip(
            label: 'Analyzing…',
            color: Color(0xFFB26A00),
            icon: Icons.hourglass_top);
      case ClassifyStatus.success:
        return const StatusChip(
            label: 'Detected', color: AppColors.primary, icon: Icons.check_circle);
      case ClassifyStatus.empty:
        return const StatusChip(
            label: 'No coconut found',
            color: Color(0xFFB26A00),
            icon: Icons.search_off);
      case ClassifyStatus.error:
        return const StatusChip(
            label: 'Failed', color: AppColors.error, icon: Icons.error_outline);
    }
  }

  /// EMPTY branch of the flow.
  Widget _emptyPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search_off, color: Color(0xFFB26A00), size: 26),
                const SizedBox(width: 10),
                const Text('No coconut detected',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'The photo does not show a coconut that the model can recognise. '
              'Use a clear, well-lit photo of a single coconut on a plain background.',
              style: TextStyle(fontSize: 13, color: AppColors.grey600, height: 1.45),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Try another photo',
              variant: AppButtonVariant.outlined,
              icon: Icons.photo_library_outlined,
              onPressed: _loading ? null : _pick,
            ),
          ],
        ),
      ),
    );
  }

  /// LOADING branch of the flow.
  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Analyzing photo…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _loading ? null : _pick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey400, style: BorderStyle.solid),
            ),
            child: _file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: AppColors.grey400),
                      const SizedBox(height: 8),
                      Text('Tap to choose a photo', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text('JPEG or PNG, up to 5 MB', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey600)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_file!.bytes, fit: BoxFit.contain),
                  ),
          ),
        ),
        if (_fileError != null) ...[
          const SizedBox(height: 8),
          Text(_fileError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        if (_file != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(_file!.name, overflow: TextOverflow.ellipsis)),
              TextButton(onPressed: _loading ? null : _remove, child: const Text('Remove')),
            ],
          ),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: _loading ? 'Classifying…' : 'Classify',
          loading: _loading,
          onPressed: _classify,
          fullWidth: true,
          icon: Icons.search,
        ),
      ],
    );
  }

  Widget _tipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Photo tips', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('• Use a clear, well-lit photo of the coconut.'),
            Text('• Center the subject; avoid blur.'),
            Text('• Only JPEG or PNG files are accepted.'),
            Text('• Maximum file size is 5 MB.'),
          ],
        ),
      ),
    );
  }
}

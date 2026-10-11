import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/services/tts_service.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Specification for a single spotlighted step during the dashboard tour.
class TourStepItem {
  final GlobalKey targetKey;
  final IconData icon;
  final String titleMr;
  final String titleHi;
  final String titleEn;
  final String descMr;
  final String descHi;
  final String descEn;
  final String audioMr;
  final String audioHi;
  final String audioEn;

  const TourStepItem({
    required this.targetKey,
    required this.icon,
    required this.titleMr,
    required this.titleHi,
    required this.titleEn,
    required this.descMr,
    required this.descHi,
    required this.descEn,
    required this.audioMr,
    required this.audioHi,
    required this.audioEn,
  });

  String getTitle(String lang) {
    if (lang == 'mr') return titleMr;
    if (lang == 'hi') return titleHi;
    return titleEn;
  }

  String getDesc(String lang) {
    if (lang == 'mr') return descMr;
    if (lang == 'hi') return descHi;
    return descEn;
  }

  String getAudio(String lang) {
    if (lang == 'mr') return audioMr;
    if (lang == 'hi') return audioHi;
    return audioEn;
  }
}

/// Fullscreen interactive Spotlight Overlay.
/// Dims the background, spotlights each targeted widget with an animated glowing cutout and pulse ring,
/// provides spoken voice explanations in Marathi, Hindi, and English,
/// and eliminates any pixel overflows with responsive bounds clamping.
class FeatureTourOverlay extends StatefulWidget {
  final List<TourStepItem> steps;
  final ScrollController? scrollController;
  final VoidCallback onFinish;

  const FeatureTourOverlay({
    super.key,
    required this.steps,
    this.scrollController,
    required this.onFinish,
  });

  /// Helper to display the overlay over the existing Navigator context.
  static void show(
    BuildContext context, {
    required List<TourStepItem> steps,
    ScrollController? scrollController,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return FeatureTourOverlay(
          steps: steps,
          scrollController: scrollController,
          onFinish: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final TtsService _ttsService = TtsService();
  bool _isPlayingAudio = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ttsService.isSpeakingNotifier.addListener(_onTtsStateChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTarget();
      _playCurrentAudio();
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.isSpeakingNotifier.removeListener(_onTtsStateChange);
    _ttsService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTtsStateChange() {
    if (mounted) {
      setState(() {
        _isPlayingAudio = _ttsService.isSpeakingNotifier.value;
      });
    }
  }

  TourStepItem get _currentStep => widget.steps[_currentIndex];

  void _scrollToCurrentTarget() {
    final key = _currentStep.targetKey;
    final context = key.currentContext;
    if (context != null && widget.scrollController != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.35,
      );
      // Re-trigger layout measurement after scroll finishes
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted) setState(() {});
      });
    }
  }

  void _playCurrentAudio() {
    final lang = context.locale.languageCode;
    final audioText = _currentStep.getAudio(lang);
    _ttsService.speak(audioText, languageCode: lang);
  }

  void _toggleAudio() {
    if (_isPlayingAudio) {
      _ttsService.stop();
    } else {
      _playCurrentAudio();
    }
  }

  void _nextStep() {
    _ttsService.stop();
    if (_currentIndex < widget.steps.length - 1) {
      setState(() {
        _currentIndex++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTarget();
        _playCurrentAudio();
      });
    } else {
      widget.onFinish();
    }
  }

  void _prevStep() {
    _ttsService.stop();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTarget();
        _playCurrentAudio();
      });
    }
  }

  void _switchLanguage(String code) {
    context.setLocale(Locale(code));
    _ttsService.stop();
    Future.microtask(() {
      if (mounted) {
        _playCurrentAudio();
      }
    });
  }

  Rect? _calculateTargetRect() {
    final key = _currentStep.targetKey;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(
      position.dx - 6,
      position.dy - 6,
      size.width + 12,
      size.height + 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentLang = context.locale.languageCode;
    final targetRect = _calculateTargetRect();

    // Fallback if target is offscreen or not rendered yet
    final safeTargetRect = targetRect ??
        Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height * 0.35),
          width: screenSize.width * 0.88,
          height: 120,
        );

    final isTargetInTopHalf = safeTargetRect.center.dy < screenSize.height * 0.52;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _ttsService.stop();
          widget.onFinish();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Dark backdrop with illuminated cutout hole over the highlighted feature
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  size: screenSize,
                  painter: _SpotlightHolePainter(
                    targetRect: safeTargetRect,
                    pulseFactor: _pulseController.value,
                  ),
                );
              },
            ),

            // 2. Translucent dismiss / interaction layer
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // User taps outside card: keep tour active
                },
              ),
            ),

            // 3. Highlighted Element Glowing Outline with Pulse Animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = _pulseController.value;
                return Positioned(
                  left: max(4.0, safeTargetRect.left),
                  top: max(4.0, safeTargetRect.top),
                  width: min(screenSize.width - 8.0, safeTargetRect.width),
                  height: safeTargetRect.height,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        // Glow only: soft white light that breathes, no
                        // coloured ring, so the control keeps its own look.
                        border: Border.all(
                          color: AppColors.spotlight.withValues(alpha: 0.55 + (pulse * 0.35)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.spotlight.withValues(alpha: 0.30 + (pulse * 0.35)),
                            blurRadius: 18.0 + (pulse * 14.0),
                            spreadRadius: 1.0 + (pulse * 4.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 4. Visual Indicator Badge Pointing to the Highlighted Thing
            Positioned(
              left: max(16.0, safeTargetRect.center.dx - 80),
              top: isTargetInTopHalf
                  ? max(safeTargetRect.top - 32, 28)
                  : min(safeTargetRect.bottom + 8, screenSize.height - 40),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.spotlight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTargetInTopHalf ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: AppColors.onSurface,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentLang == 'mr'
                            ? 'हे फिचर पहा'
                            : currentLang == 'hi'
                                ? 'यह फीचर देखें'
                                : 'Look here',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Floating Explanation & Audio Control Card
            Positioned(
              left: 16,
              right: 16,
              top: isTargetInTopHalf
                  ? min(screenSize.height - 350, max(safeTargetRect.bottom + 16, 80))
                  : null,
              bottom: isTargetInTopHalf
                  ? null
                  : min(screenSize.height - 350, max((screenSize.height - safeTargetRect.top) + 16, 80)),
              child: _buildTooltipCard(context, currentLang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipCard(BuildContext context, String currentLang) {
    final title = _currentStep.getTitle(currentLang);
    final desc = _currentStep.getDesc(currentLang);
    final isLast = _currentIndex == widget.steps.length - 1;

    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Step indicator + Language Switchers + Close Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.steps.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                // Language selection pills directly on the tour card
                _buildLanguageTogglePill('mr', 'मराठी', currentLang == 'mr'),
                const SizedBox(width: 4),
                _buildLanguageTogglePill('hi', 'हिंदी', currentLang == 'hi'),
                const SizedBox(width: 4),
                _buildLanguageTogglePill('en', 'EN', currentLang == 'en'),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _ttsService.stop();
                    widget.onFinish();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 22, color: AppColors.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Feature Title with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_currentStep.icon, color: AppColors.primaryContainer, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detailed Explanation Text
            Text(
              desc,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Audio Player Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isPlayingAudio ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPlayingAudio ? AppColors.primaryFixedDim : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    color: _isPlayingAudio ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPlayingAudio
                          ? (currentLang == 'mr'
                              ? 'माहिती बोलत आहे... 🔊'
                              : currentLang == 'hi'
                                  ? 'जानकारी सुनाई जा रही है... 🔊'
                                  : 'Speaking instructions... 🔊')
                          : (currentLang == 'mr'
                              ? 'आवाज ऐका (Voice Audio)'
                              : currentLang == 'hi'
                                  ? 'आवाज सुनें (Voice Audio)'
                                  : 'Listen to Voice Guide'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isPlayingAudio ? AppColors.primary : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _toggleAudio,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isPlayingAudio ? AppColors.primaryContainer : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isPlayingAudio ? AppColors.primaryContainer : AppColors.outline,
                        ),
                      ),
                      child: Text(
                        _isPlayingAudio
                            ? (currentLang == 'mr'
                                ? 'थांबवा'
                                : currentLang == 'hi'
                                    ? 'रोकें'
                                    : 'Pause')
                            : (currentLang == 'mr'
                                ? 'ऐका 🔊'
                                : currentLang == 'hi'
                                    ? 'सुनें 🔊'
                                    : 'Play 🔊'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isPlayingAudio ? Colors.white : AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Navigation (Previous & Next buttons)
            Row(
              children: [
                if (_currentIndex > 0) ...[
                  OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      currentLang == 'mr' ? 'मागे' : currentLang == 'hi' ? 'पीछे' : 'Back',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      isLast
                          ? (currentLang == 'mr'
                              ? 'समजले / समाप्त'
                              : currentLang == 'hi'
                                  ? 'समझ गए / पूरा हुआ'
                                  : 'Finish Tour')
                          : (currentLang == 'mr'
                              ? 'पुढील भाग'
                              : currentLang == 'hi'
                                  ? 'आगे बढ़ें'
                                  : 'Next'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTogglePill(String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _switchLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Custom painter cutting a transparent rounded rectangle cutout over the target widget
/// while darkening the rest of the display with soft pulsating halo.
class _SpotlightHolePainter extends CustomPainter {
  final Rect targetRect;
  final double pulseFactor;

  _SpotlightHolePainter({
    required this.targetRect,
    required this.pulseFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final haloPaint = Paint()
      ..color = AppColors.spotlight.withValues(alpha: 0.10 + (pulseFactor * 0.15))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 + (pulseFactor * 6.0)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + pulseFactor * 4);

    final wholeScreen = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutRRect = RRect.fromRectAndRadius(
      targetRect,
      const Radius.circular(18),
    );
    final cutoutPath = Path()..addRRect(cutoutRRect);

    // Difference between screen and cutout creates the transparent hole
    final transparentHole = Path.combine(
      PathOperation.difference,
      wholeScreen,
      cutoutPath,
    );

    canvas.drawPath(transparentHole, backgroundPaint);
    canvas.drawRRect(cutoutRRect, haloPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightHolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.pulseFactor != pulseFactor;
  }
}

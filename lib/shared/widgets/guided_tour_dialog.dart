import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/services/tts_service.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Interactive Multi-lingual Guided Tour for rural patients.
/// Supports Marathi, Hindi, and English with real TTS voice playback,
/// high-contrast visual steps, audio cues, and zero pixel overflow.
class GuidedTourDialog extends StatefulWidget {
  final VoidCallback? onStartSpotlightTour;

  const GuidedTourDialog({super.key, this.onStartSpotlightTour});

  static Future<void> show(BuildContext context, {VoidCallback? onStartSpotlightTour}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => GuidedTourDialog(onStartSpotlightTour: onStartSpotlightTour),
    );
  }

  @override
  State<GuidedTourDialog> createState() => _GuidedTourDialogState();
}

class _GuidedTourDialogState extends State<GuidedTourDialog> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  final TtsService _ttsService = TtsService();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _ttsService.isSpeakingNotifier.addListener(_onTtsStateChanged);
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.isSpeakingNotifier.removeListener(_onTtsStateChanged);
    _ttsService.dispose();
    super.dispose();
  }

  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {
        _isPlayingAudio = _ttsService.isSpeakingNotifier.value;
      });
    }
  }

  void _speakCurrentStepAudio(String textHindi, String textMarathi, String textEnglish) {
    final lang = context.locale.languageCode;
    final text = lang == 'mr'
        ? textMarathi
        : lang == 'hi'
            ? textHindi
            : textEnglish;

    if (_isPlayingAudio) {
      _ttsService.stop();
    } else {
      _ttsService.speak(text, languageCode: lang);
    }
  }

  void _next() {
    _ttsService.stop();
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    _ttsService.stop();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar: Step Indicator & Language Switcher (Zero Overflow)
            _buildTopBar(context, currentLocale),

            // Step Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildCurrentStepContent(context),
              ),
            ),

            // Bottom Navigation Actions
            _buildBottomControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String currentLocale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tr('guided_tour_step', args: ['${_currentStep + 1}', '$_totalSteps']),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildLanguageSelector(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: tr('close'),
                onPressed: () {
                  _ttsService.stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isCurrent = index == _currentStep;
              final isPast = index < _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isPast
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.disabled.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangPill(context, 'mr', 'मराठी'),
          _buildLangPill(context, 'hi', 'हिंदी'),
          _buildLangPill(context, 'en', 'Eng'),
        ],
      ),
    );
  }

  Widget _buildLangPill(BuildContext context, String code, String label) {
    final isSelected = context.locale.languageCode == code;
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(code));
        _ttsService.stop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Language();
      case 1:
        return _buildStep2Booking();
      case 2:
        return _buildStep3Records();
      case 3:
        return _buildStep4EmergencyAndAsha();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: Language & Overview
  Widget _buildStep1Language() {
    const hindiAudio = 'नमस्ते! आप इस ऐप में हिंदी, मराठी या अंग्रेजी कभी भी बदल सकते हैं।';
    const marathiAudio = 'नमस्कार! आपण या ॲपमध्ये मराठी, हिंदी किंवा इंग्रजी कधीही निवडू शकता.';
    const englishAudio = 'Welcome! You can change between Marathi, Hindi and English anytime.';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            Icons.translate_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('tour_lang_title'),
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          tr('tour_lang_desc'),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildAudioHint(
          audioTextHindi: hindiAudio,
          audioTextMarathi: marathiAudio,
          audioTextEnglish: englishAudio,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.locale.languageCode == 'mr'
                      ? 'वर दिलेल्या बटणावर टॅप करून भाषा बदला.'
                      : context.locale.languageCode == 'hi'
                          ? 'ऊपर दिए गए बटन पर दबाकर भाषा बदल सकते हैं।'
                          : 'Tap buttons above to switch language instantly.',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 1: Booking an Appointment
  Widget _buildStep2Booking() {
    const hindiAudio = 'अपॉइंटमेंट बुक करने के बाद आपको अस्पताल में लाइन में नहीं लगना पड़ेगा।';
    const marathiAudio = 'अपॉइंटमेंट बुक केल्यावर तुम्हाला दवाखान्यात ताटकळत बसावे लागणार नाही.';
    const englishAudio = 'Booking beforehand saves your time and avoids long hospital queues.';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 40,
            color: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('tour_book_title'),
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        _buildVisualChecklist([
          (
            number: '१',
            title: context.locale.languageCode == 'mr'
                ? 'गाव निवडा (Select Village)'
                : context.locale.languageCode == 'hi'
                    ? 'गाँव चुनें (Select Village)'
                    : 'Select Village',
            subtitle: context.locale.languageCode == 'mr'
                ? 'तुमच्या जवळचे आरोग्य केंद्र दिसेल'
                : context.locale.languageCode == 'hi'
                    ? 'आपके गाँव का स्वास्थ्य केंद्र दिखेगा'
                    : 'Shows your nearby health center',
            icon: Icons.location_on_outlined,
          ),
          (
            number: '२',
            title: context.locale.languageCode == 'mr'
                ? 'डॉक्टर निवडा (Select Doctor)'
                : context.locale.languageCode == 'hi'
                    ? 'डॉक्टर चुनें (Select Doctor)'
                    : 'Choose Available Doctor',
            subtitle: context.locale.languageCode == 'mr'
                ? 'उपलब्ध डॉक्टरांची यादी तपासा'
                : context.locale.languageCode == 'hi'
                    ? 'उपलब्ध डॉक्टर की सूची देखें'
                    : 'View registered doctor list',
            icon: Icons.person_search_outlined,
          ),
          (
            number: '३',
            title: context.locale.languageCode == 'mr'
                ? 'तारीख व वेळ निवडा'
                : context.locale.languageCode == 'hi'
                    ? 'तारीख और समय चुनें'
                    : 'Pick Date & Time Slot',
            subtitle: context.locale.languageCode == 'mr'
                ? 'सोयीची वेळ निवडून पुष्टी करा'
                : context.locale.languageCode == 'hi'
                    ? 'सुविधाजनक समय चुनकर पुष्टि करें'
                    : 'Confirm your convenient slot',
            icon: Icons.check_circle_outline,
          ),
        ]),
        const SizedBox(height: 14),
        _buildAudioHint(
          audioTextHindi: hindiAudio,
          audioTextMarathi: marathiAudio,
          audioTextEnglish: englishAudio,
        ),
      ],
    );
  }

  /// Step 2: Health Records & Prescriptions
  Widget _buildStep3Records() {
    const hindiAudio = 'कागज़ की पर्ची खो जाने की कोई चिंता नहीं, सब कुछ ऐप में सुरक्षित है।';
    const marathiAudio = 'कागदाची चिठ्ठी गहाळ होण्याची भीती नाही, सर्व माहिती ॲपमध्ये सुरक्षित राहते.';
    const englishAudio = 'No fear of losing paper slips, your prescription is safely stored in app.';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            size: 40,
            color: AppColors.info,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('tour_records_title'),
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          tr('tour_records_desc'),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryFixedDim),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.check_box_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.locale.languageCode == 'mr'
                          ? 'डॉक्टरांनी लिहून दिलेली औषधे नेहमी फोनमध्ये राहतील'
                          : context.locale.languageCode == 'hi'
                              ? 'डॉक्टर द्वारा लिखी गई दवाइयां हमेशा फोन में उपलब्ध रहेंगी'
                              : 'Prescriptions are always saved in your phone',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_box_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.locale.languageCode == 'mr'
                          ? 'पुढील भेटीची तारीख आणि तपासणी तपशील'
                          : context.locale.languageCode == 'hi'
                              ? 'अगली मुलाकात की तारीख और चेकअप विवरण'
                              : 'Follow-up dates and clinical summary',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildAudioHint(
          audioTextHindi: hindiAudio,
          audioTextMarathi: marathiAudio,
          audioTextEnglish: englishAudio,
        ),
      ],
    );
  }

  /// Step 3: Village ASHA & Emergency Help
  Widget _buildStep4EmergencyAndAsha() {
    const hindiAudio = 'अगर आपको फोन चलाने में दिक्कत हो तो अपने गाँव की आशा दीदी से सहायता लें।';
    const marathiAudio = 'फॉर्म भरण्यास अडचण असल्यास आपल्या गावातील आशा सेविकेची मदत घ्या.';
    const englishAudio = 'If you face any difficulty, ask your village ASHA worker for help.';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 40,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('tour_help_title'),
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          tr('tour_help_desc'),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildHelpRow(
                icon: Icons.emergency_rounded,
                iconColor: AppColors.error,
                title: tr('emergency_ambulance'),
                desc: '108 (२४ तास विनामूल्य / 24 Hours Free)',
              ),
              const Divider(height: 14),
              _buildHelpRow(
                icon: Icons.phone_in_talk_rounded,
                iconColor: AppColors.info,
                title: tr('emergency_health_call'),
                desc: '104 (आरोग्य सल्ला व मार्गदर्शन)',
              ),
              const Divider(height: 14),
              _buildHelpRow(
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.primary,
                title: tr('asha_worker_support'),
                desc: tr('asha_support_desc'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildAudioHint(
          audioTextHindi: hindiAudio,
          audioTextMarathi: marathiAudio,
          audioTextEnglish: englishAudio,
        ),
      ],
    );
  }

  Widget _buildHelpRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                desc,
                style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualChecklist(
      List<({String number, String title, String subtitle, IconData icon})> items) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(item.icon, color: AppColors.primary, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudioHint({
    required String audioTextHindi,
    required String audioTextMarathi,
    required String audioTextEnglish,
  }) {
    final lang = context.locale.languageCode;
    final text = lang == 'mr'
        ? audioTextMarathi
        : lang == 'hi'
            ? audioTextHindi
            : audioTextEnglish;

    return InkWell(
      onTap: () => _speakCurrentStepAudio(audioTextHindi, audioTextMarathi, audioTextEnglish),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isPlayingAudio
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isPlayingAudio
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isPlayingAudio ? text : '🔊 ${tr("tour_listen")}: "$text"',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurface,
                  fontStyle: FontStyle.italic,
                  fontWeight: _isPlayingAudio ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isPlayingAudio ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isPlayingAudio ? 'थांबवा / Stop' : 'ऐका / Play',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isPlayingAudio ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _previous,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: Text(
                        tr('previous'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                      isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLastStep ? tr('tour_got_it') : tr('next_step'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.onStartSpotlightTour != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _ttsService.stop();
                Navigator.of(context).pop();
                widget.onStartSpotlightTour?.call();
              },
              icon: const Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.primary),
              label: Text(
                context.locale.languageCode == 'mr'
                    ? 'स्क्रीनवर फिचर हायलाइट करा (Interactive Tour)'
                    : context.locale.languageCode == 'hi'
                        ? 'स्क्रीन पर फीचर देखें (Interactive Tour)'
                        : 'Spotlight Features on Screen',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

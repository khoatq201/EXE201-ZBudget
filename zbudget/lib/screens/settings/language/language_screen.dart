import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../services/language_service.dart';
import '../../../models/settings/language_settings.dart';
import '../../../utils/theme_extensions.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with TickerProviderStateMixin {
  final LanguageService _languageService = LanguageService();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _languageService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: context.headerGradientStart,
            foregroundColor: context.colorScheme.onPrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Ngôn ngữ & Định dạng',
                style: AppTypography.h3.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.headerGradientStart,
                      context.headerGradientEnd,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Text(
                        _languageService.currentLanguageFlag,
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Overview Card
                        _buildLanguageOverviewCard(),
                        const SizedBox(height: 24),

                        // Auto Detect Toggle
                        _buildAutoDetectSection(),
                        const SizedBox(height: 24),

                        // Language Selection Section
                        _buildSectionHeader('Chọn ngôn ngữ'),
                        const SizedBox(height: 16),
                        _buildLanguageSearchBar(),
                        const SizedBox(height: 16),
                        _buildLanguageSelectionSection(),
                        const SizedBox(height: 24),

                        // Format Settings Section
                        _buildSectionHeader('Định dạng'),
                        const SizedBox(height: 16),
                        _buildFormatSettingsSection(),
                        const SizedBox(height: 24),

                        // Preview Section
                        _buildSectionHeader('Xem trước'),
                        const SizedBox(height: 16),
                        _buildPreviewSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOverviewCard() {
    final stats = _languageService.getLanguageStatistics();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.settingsItemIconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _languageService.currentLanguageFlag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _languageService.currentLanguageName,
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.settingsItemTitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _languageService.currentLanguage.englishName,
                      style: AppTypography.body.copyWith(
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.settingsItemIconBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stats['currentRegion'],
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Ngôn ngữ',
                '${stats['totalLanguages']}',
                Icons.language,
              ),
              _buildStatItem('Định dạng', '4', Icons.format_list_numbered),
              _buildStatItem('Múi giờ', 'GMT+7', Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: context.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.settingsItemSubtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoDetectSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.settingsItemIconBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: context.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Tự động phát hiện ngôn ngữ',
          style: AppTypography.body.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _languageService.languageSettings.autoDetectLanguage
              ? 'Sử dụng ngôn ngữ của hệ thống'
              : 'Chọn ngôn ngữ thủ công',
          style: AppTypography.bodySmall.copyWith(
            color: context.settingsItemSubtitleColor,
          ),
        ),
        trailing: Switch(
          value: _languageService.languageSettings.autoDetectLanguage,
          activeThumbColor: context.colorScheme.primary,
          onChanged: (value) {
            _languageService.toggleAutoDetectLanguage(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm ngôn ngữ...',
          prefixIcon: Icon(
            Icons.search,
            color: context.settingsItemSubtitleColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.inputFieldBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionSection() {
    final languages = _searchQuery.isEmpty
        ? _languageService.getAllLanguages()
        : _languageService.searchLanguages(_searchQuery);

    if (languages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: context.settingsItemSubtitleColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy ngôn ngữ',
              style: AppTypography.body.copyWith(
                color: context.settingsItemSubtitleColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Asian Languages
        if (_searchQuery.isEmpty) ...[
          _buildLanguageGroup('Châu Á', _languageService.getAsianLanguages()),
          const SizedBox(height: 16),
          _buildLanguageGroup(
            'Châu Âu & Mỹ',
            _languageService.getEuropeanLanguages(),
          ),
        ] else ...[
          _buildLanguageGroup('Kết quả tìm kiếm', languages),
        ],
      ],
    );
  }

  Widget _buildLanguageGroup(String title, List<AppLanguage> languages) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                color: context.settingsItemSubtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          ...languages.asMap().entries.map((entry) {
            final index = entry.key;
            final language = entry.value;
            final isSelected = _languageService.currentLanguage == language;
            final isLast = index == languages.length - 1;

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.settingsItemIconBackground
                          : context.settingsItemIconBackground.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  title: Text(
                    language.nativeName,
                    style: AppTypography.body.copyWith(
                      color: context.settingsItemTitleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    language.englishName,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                    ),
                  ),
                  trailing: Radio<AppLanguage>(
                    value: language,
                    groupValue: _languageService.currentLanguage,
                    activeColor: context.colorScheme.primary,
                    onChanged: (value) {
                      if (value != null) {
                        _languageService.updateLanguage(value);
                        setState(() {});
                      }
                    },
                  ),
                  onTap: () {
                    _languageService.updateLanguage(language);
                    setState(() {});
                  },
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFormatSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Format
          _buildFormatTile(
            icon: Icons.calendar_today,
            title: 'Định dạng ngày',
            subtitle: _languageService.getDateFormatDisplayName(),
            example: _languageService.getSampleDate(),
            onTap: () => _showDateFormatDialog(),
            showDivider: true,
          ),

          // Number Format
          _buildFormatTile(
            icon: Icons.numbers,
            title: 'Định dạng số',
            subtitle: _languageService.getNumberFormatDisplayName(),
            example: _languageService.getSampleNumber(),
            onTap: () => _showNumberFormatDialog(),
            showDivider: true,
          ),

          // Currency Format
          _buildFormatTile(
            icon: Icons.currency_exchange,
            title: 'Định dạng tiền tệ',
            subtitle: _languageService.getCurrencyFormatDisplayName(),
            example: _languageService.getSampleCurrency(),
            onTap: () => _showCurrencyFormatDialog(),
            showDivider: true,
          ),

          // Time Format
          _buildFormatTile(
            icon: Icons.access_time,
            title: 'Định dạng thời gian',
            subtitle: _languageService.getTimeFormatDisplayName(),
            example: _languageService.getSampleTime(),
            trailing: Switch(
              value: _languageService.languageSettings.use24HourFormat,
              activeThumbColor: AppColors.primary500,
              onChanged: (value) {
                _languageService.toggle24HourFormat(value);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String example,
    VoidCallback? onTap,
    Widget? trailing,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.settingsItemIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.colorScheme.primary, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: context.settingsItemSubtitleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ví dụ: $example',
                style: AppTypography.caption.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing:
              trailing ??
              (onTap != null
                  ? Icon(
                      Icons.chevron_right,
                      color: context.settingsItemSubtitleColor,
                    )
                  : null),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem trước định dạng',
              style: AppTypography.body.copyWith(
                color: context.settingsItemSubtitleColor,
              ),
            ),
            const SizedBox(height: 16),

            // Preview card
            Container(
              decoration: BoxDecoration(
                color: context.inputFieldBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _languageService.currentLanguageFlag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _languageService.currentLanguageName,
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.settingsItemTitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildPreviewItem('Ngày:', _languageService.getSampleDate()),
                  _buildPreviewItem('Số:', _languageService.getSampleNumber()),
                  _buildPreviewItem(
                    'Tiền tệ:',
                    _languageService.getSampleCurrency(),
                  ),
                  _buildPreviewItem(
                    'Thời gian:',
                    _languageService.getSampleTime(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reset button
            Center(
              child: TextButton.icon(
                onPressed: () => _showResetDialog(),
                icon: const Icon(Icons.restore),
                label: const Text('Đặt lại về mặc định'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: context.settingsItemSubtitleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: context.settingsItemTitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        fontWeight: FontWeight.bold,
        color: context.settingsItemTitleColor,
      ),
    );
  }

  // Dialog methods
  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Định dạng ngày'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DateFormat.values.map((format) {
            return RadioListTile<DateFormat>(
              title: Text(format.display),
              subtitle: Text(
                _languageService.languageSettings
                    .copyWith(dateFormat: format)
                    .formatDate(DateTime.now()),
              ),
              value: format,
              groupValue: _languageService.languageSettings.dateFormat,
              activeColor: AppColors.primary500,
              onChanged: (value) {
                if (value != null) {
                  _languageService.updateDateFormat(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showNumberFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Định dạng số'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NumberFormat.values.map((format) {
            return RadioListTile<NumberFormat>(
              title: Text(format.displayName),
              subtitle: Text('Ví dụ: ${format.example}'),
              value: format,
              groupValue: _languageService.languageSettings.numberFormat,
              activeColor: AppColors.primary500,
              onChanged: (value) {
                if (value != null) {
                  _languageService.updateNumberFormat(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Định dạng tiền tệ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CurrencyFormat.values.map((format) {
            return RadioListTile<CurrencyFormat>(
              title: Text(format.displayName),
              subtitle: Text('Ví dụ: ${format.example}'),
              value: format,
              groupValue: _languageService.languageSettings.currencyFormat,
              activeColor: AppColors.primary500,
              onChanged: (value) {
                if (value != null) {
                  _languageService.updateCurrencyFormat(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại cài đặt ngôn ngữ'),
        content: const Text(
          'Bạn có chắc chắn muốn đặt lại tất cả cài đặt ngôn ngữ và định dạng về mặc định?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _languageService.resetToDefaults();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đặt lại cài đặt ngôn ngữ về mặc định'),
                ),
              );
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}

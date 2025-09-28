import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/currency_service.dart';
import '../../../models/settings/currency_settings.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final TextEditingController _converterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyService>().initialize();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _converterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CurrencyService>(
        builder: (context, currencyService, child) {
          if (currencyService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, currencyService),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverviewCard(currencyService),
                              const SizedBox(height: AppSpacing.xl),
                              _buildPrimaryCurrencySection(currencyService),
                              const SizedBox(height: AppSpacing.xl),
                              _buildDisplayOptionsSection(currencyService),
                              const SizedBox(height: AppSpacing.xl),
                              _buildAdvancedOptionsSection(currencyService),
                              const SizedBox(height: AppSpacing.xl),
                              _buildPreviewSection(currencyService),
                              if (currencyService
                                  .settings
                                  .showCurrencyConverter) ...[
                                const SizedBox(height: AppSpacing.xl),
                                _buildConverterSection(currencyService),
                              ],
                              const SizedBox(height: AppSpacing.xl5),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    CurrencyService currencyService,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary500,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Currency',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientPrimary,
            ),
          ),
        ),
      ),
      actions: [
        if (currencyService.isUpdatingRates)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => currencyService.updateExchangeRates(),
            tooltip: 'Update exchange rates',
          ),
      ],
    );
  }

  Widget _buildOverviewCard(CurrencyService currencyService) {
    final stats = currencyService.getCurrencyStats();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary500,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currency Overview',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Primary: ${currencyService.settings.primaryCurrency.name}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Currencies',
                    '${stats['totalCurrencies']}',
                    Icons.public,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Favorites',
                    '${stats['favoritesCount']}',
                    Icons.favorite,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Auto Update',
                    stats['autoUpdate'] ? 'ON' : 'OFF',
                    Icons.update,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary500, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrimaryCurrencySection(CurrencyService currencyService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Currency',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Select your main currency for transactions',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: Text(
              currencyService.settings.primaryCurrency.flag,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(currencyService.settings.primaryCurrency.name),
            subtitle: Text(
              '${currencyService.settings.primaryCurrency.code} • ${currencyService.settings.primaryCurrency.symbol}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCurrencySelector(context, currencyService, true),
          ),
        ),
        if (currencyService.settings.enableMultiCurrency) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Secondary Currency (Optional)',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: Text(
                currencyService.settings.secondaryCurrency?.flag ?? '🌍',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                currencyService.settings.secondaryCurrency?.name ??
                    'None selected',
              ),
              subtitle: currencyService.settings.secondaryCurrency != null
                  ? Text(
                      '${currencyService.settings.secondaryCurrency!.code} • ${currencyService.settings.secondaryCurrency!.symbol}',
                    )
                  : const Text('Tap to select secondary currency'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () =>
                  _showCurrencySelector(context, currencyService, false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDisplayOptionsSection(CurrencyService currencyService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Options',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.format_paint),
                title: const Text('Currency Format'),
                subtitle: Text(
                  currencyService.settings.displayFormat.description,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFormatSelector(context, currencyService),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('Number Format'),
                subtitle: Text(
                  currencyService.settings.numberSeparator.example,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    _showNumberFormatSelector(context, currencyService),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Rounding'),
                subtitle: Text(currencyService.settings.roundingMode.title),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRoundingSelector(context, currencyService),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsSection(CurrencyService currencyService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.trending_up),
                title: const Text('Show Exchange Rates'),
                subtitle: const Text('Display current exchange rates'),
                value: currencyService.settings.showExchangeRate,
                onChanged: currencyService.toggleExchangeRateDisplay,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.update),
                title: const Text('Auto Update Rates'),
                subtitle: const Text(
                  'Automatically update exchange rates daily',
                ),
                value: currencyService.settings.autoUpdateRates,
                onChanged: currencyService.toggleAutoUpdateRates,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.calculate),
                title: const Text('Currency Converter'),
                subtitle: const Text('Enable built-in currency converter'),
                value: currencyService.settings.showCurrencyConverter,
                onChanged: currencyService.toggleCurrencyConverter,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.language),
                title: const Text('Multi-Currency Support'),
                subtitle: const Text(
                  'Support multiple currencies in transactions',
                ),
                value: currencyService.settings.enableMultiCurrency,
                onChanged: currencyService.toggleMultiCurrency,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(CurrencyService currencyService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'See how amounts will be displayed',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: currencyService.previewAmounts.map((amount) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        amount.toString(),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyService.formatAmount(amount),
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConverterSection(CurrencyService currencyService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency Converter',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _converterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: currencyService.settings.primaryCurrency.symbol,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_converterController.text.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    children: Currency.majorCurrencies
                        .where(
                          (c) => c != currencyService.settings.primaryCurrency,
                        )
                        .take(5)
                        .map((currency) {
                          final amount =
                              double.tryParse(_converterController.text) ?? 0;
                          final convertedAmount = currencyService.settings
                              .convertAmount(amount, currency);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    currency.name,
                                    style: AppTypography.body,
                                  ),
                                ),
                                Text(
                                  '${currency.symbol}${convertedAmount.toStringAsFixed(2)}',
                                  style: AppTypography.h6.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencySelector(
    BuildContext context,
    CurrencyService currencyService,
    bool isPrimary,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isPrimary
                        ? 'Select Primary Currency'
                        : 'Select Secondary Currency',
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search currencies...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_searchQuery.isEmpty) ...[
                    if (currencyService.favoriteCurrencies.isNotEmpty) ...[
                      _buildCurrencyGroup(
                        'Favorites',
                        currencyService.favoriteCurrencies,
                        currencyService,
                        isPrimary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _buildCurrencyGroup(
                      'Popular',
                      currencyService.popularCurrencies,
                      currencyService,
                      isPrimary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  ...Currency.currenciesByRegion.entries.map((entry) {
                    final filteredCurrencies = _searchQuery.isEmpty
                        ? entry.value
                        : entry.value
                              .where(
                                (c) => currencyService
                                    .searchCurrencies(_searchQuery)
                                    .contains(c),
                              )
                              .toList();

                    if (filteredCurrencies.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        _buildCurrencyGroup(
                          entry.key,
                          filteredCurrencies,
                          currencyService,
                          isPrimary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyGroup(
    String title,
    List<Currency> currencies,
    CurrencyService currencyService,
    bool isPrimary,
  ) {
    if (currencies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...currencies.map(
          (currency) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ListTile(
              leading: Text(
                currency.flag,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(currency.name),
              subtitle: Text('${currency.code} • ${currency.symbol}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      currencyService.favoriteCurrencies.contains(currency)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          currencyService.favoriteCurrencies.contains(currency)
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () => currencyService.toggleFavorite(currency),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () {
                if (isPrimary) {
                  currencyService.updatePrimaryCurrency(currency);
                } else {
                  currencyService.updateSecondaryCurrency(currency);
                }
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showFormatSelector(
    BuildContext context,
    CurrencyService currencyService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CurrencyDisplayFormat.values.map((format) {
            return RadioListTile<CurrencyDisplayFormat>(
              title: Text(format.description),
              subtitle: Text(format.example),
              value: format,
              groupValue: currencyService.settings.displayFormat,
              onChanged: (value) {
                if (value != null) {
                  currencyService.updateDisplayFormat(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNumberFormatSelector(
    BuildContext context,
    CurrencyService currencyService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NumberSeparator.values.map((separator) {
            return RadioListTile<NumberSeparator>(
              title: Text(separator.example),
              value: separator,
              groupValue: currencyService.settings.numberSeparator,
              onChanged: (value) {
                if (value != null) {
                  currencyService.updateNumberSeparator(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRoundingSelector(
    BuildContext context,
    CurrencyService currencyService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rounding Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoundingMode.values.map((mode) {
            return RadioListTile<RoundingMode>(
              title: Text(mode.title),
              subtitle: Text(mode.description),
              value: mode,
              groupValue: currencyService.settings.roundingMode,
              onChanged: (value) {
                if (value != null) {
                  currencyService.updateRoundingMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

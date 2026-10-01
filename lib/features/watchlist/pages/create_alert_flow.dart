import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/crypto_icons.dart';
import '../../alert_engine/models/alert_rule.dart';
import '../../alert_engine/models/trigger_mode.dart';
import '../../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../exchanges/base/currency_pair.dart';
import '../../exchanges/base/exchange.dart';
import '../../exchanges/base/exchange_category.dart';
import '../../exchanges/registry/exchange_registry.dart';
import '../../exchanges/stocks/global_stocks_exchange.dart';
import '../../settings/services/settings_service.dart';

enum CheckUnit { seconds, minutes, hours }

enum MarketFlowType {
  none,
  crypto,
  macro,
}

class CreateAlertFlow extends StatefulWidget {
  final ExchangeRegistry registry;
  final JsonAlertRuleRepository repository;

  const CreateAlertFlow({
    super.key,
    required this.registry,
    required this.repository,
  });

  static Future<bool?> open(
    BuildContext context, {
    required ExchangeRegistry registry,
    required JsonAlertRuleRepository repository,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateAlertFlow(
          registry: registry,
          repository: repository,
        ),
      ),
    );
  }

  @override
  State<CreateAlertFlow> createState() => _CreateAlertFlowState();
}

class _CreateAlertFlowState extends State<CreateAlertFlow> {
  MarketFlowType _flowType = MarketFlowType.none;
  int _step = 1;

  // Crypto Flow State
  ExchangeCategory _selectedCategory = ExchangeCategory.all;
  Exchange? _selectedExchange;
  String _exchangeSearchQuery = '';
  List<CurrencyPair> _exchangePairs = [];
  bool _isLoadingPairs = false;
  String _pairSearchQuery = '';
  CurrencyPair? _selectedPair;

  // Macro Flow State
  String _macroCategoryFilter = 'all';
  String _macroSearchQuery = '';
  Map<String, dynamic>? _selectedMacroAsset;

  // Snapshot
  double? _currentPrice;
  bool _isLoadingPrice = false;

  // Frequency
  CheckUnit _checkUnit = CheckUnit.minutes;
  final TextEditingController _unitValueController = TextEditingController(text: '1');

  // Condition
  AlertConditionType _conditionType = AlertConditionType.percentChange;
  AlertDirection _direction = AlertDirection.bothSides;
  final TextEditingController _percentController = TextEditingController(text: '2.5');
  final TextEditingController _targetPriceController = TextEditingController();

  @override
  void dispose() {
    _unitValueController.dispose();
    _percentController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  int _calculateTotalIntervalSeconds() {
    final value = int.tryParse(_unitValueController.text.trim()) ?? 1;
    switch (_checkUnit) {
      case CheckUnit.seconds:
        return value.clamp(1, 86400);
      case CheckUnit.minutes:
        return (value * 60).clamp(1, 86400 * 7);
      case CheckUnit.hours:
        return (value * 3600).clamp(1, 86400 * 30);
    }
  }

  String _formatCalculatedInterval(String lang) {
    final val = int.tryParse(_unitValueController.text.trim()) ?? 1;
    switch (_checkUnit) {
      case CheckUnit.seconds:
        return '$val ${AppStrings.get('seconds', lang)}';
      case CheckUnit.minutes:
        return '$val ${AppStrings.get('minutes', lang)}';
      case CheckUnit.hours:
        return '$val ${AppStrings.get('hours', lang)}';
    }
  }

  void _onExchangeChosen(Exchange exchange) {
    setState(() {
      _selectedExchange = exchange;
      _step = 2;
    });
    _fetchPairsForSelectedExchange();
  }

  Future<void> _fetchPairsForSelectedExchange({bool forceRefresh = false}) async {
    if (_selectedExchange == null) return;
    setState(() => _isLoadingPairs = true);
    try {
      final pairs = await _selectedExchange!.fetchSupportedPairs(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _exchangePairs = pairs;
          _isLoadingPairs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPairs = false);
      }
    }
  }

  Future<void> _onPairChosen(CurrencyPair pair) async {
    setState(() {
      _selectedPair = pair;
      _step = 3;
      _isLoadingPrice = true;
    });

    try {
      final snapshot = await widget.registry.fetchSnapshotFrom(
        _selectedExchange!.id,
        pair,
      );
      if (snapshot != null && mounted) {
        setState(() {
          _currentPrice = snapshot.price;
          _targetPriceController.text = snapshot.price.toStringAsFixed(2);
          _isLoadingPrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  void _onMacroAssetChosen(Map<String, dynamic> asset) {
    setState(() {
      _selectedMacroAsset = asset;
      _currentPrice = (asset['price'] as num).toDouble();
      _targetPriceController.text = _currentPrice!.toStringAsFixed(2);
      _step = 2;
    });
  }

  Future<void> _saveAlert(String lang) async {
    final intervalSeconds = _calculateTotalIntervalSeconds();

    String exchangeId;
    CurrencyPair pair;

    if (_flowType == MarketFlowType.crypto) {
      if (_selectedExchange == null || _selectedPair == null) return;
      exchangeId = _selectedExchange!.id;
      pair = _selectedPair!;
    } else {
      if (_selectedMacroAsset == null) return;
      exchangeId = 'global_stocks';
      final sym = _selectedMacroAsset!['symbol'] as String;
      pair = CurrencyPair(
        baseCurrency: sym,
        counterCurrency: 'USD',
        marketSymbol: '$sym/USD',
      );
    }

    double? percent;
    double? targetPrice;

    if (_conditionType == AlertConditionType.percentChange) {
      percent = double.tryParse(_percentController.text.trim()) ?? 2.5;
    } else {
      targetPrice = double.tryParse(_targetPriceController.text.trim());
      if (targetPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('target_price_required', lang))),
        );
        return;
      }
    }

    final newRule = AlertRule.create(
      pair: pair,
      exchangeId: exchangeId,
      checkIntervalSeconds: intervalSeconds,
      conditionType: _conditionType,
      direction: _direction,
      percent: percent,
      targetPrice: targetPrice,
      currentPrice: _currentPrice,
    );

    await widget.repository.saveRule(newRule);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = context.watch<SettingsService>();
    final lang = settingsService.settings.language;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else if (_flowType != MarketFlowType.none) {
              setState(() {
                _flowType = MarketFlowType.none;
                _step = 1;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _flowType == MarketFlowType.none
              ? AppStrings.get('choose_market_step', lang)
              : (_flowType == MarketFlowType.crypto ? AppStrings.get('crypto_market_title', lang) : AppStrings.get('macro_market_title', lang)),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
      ),
      body: _buildCurrentBody(theme, lang),
    );
  }

  Widget _buildCurrentBody(ThemeData theme, String lang) {
    if (_flowType == MarketFlowType.none) {
      return _buildMarketTypeChooser(theme, lang);
    } else if (_flowType == MarketFlowType.crypto) {
      if (_step == 1) return _buildCryptoExchangePicker(theme, lang);
      if (_step == 2) return _buildCryptoPairPicker(theme, lang);
      return _buildConditionAndFrequencyStep(theme, lang);
    } else {
      if (_step == 1) return _buildMacroAssetPicker(theme, lang);
      return _buildConditionAndFrequencyStep(theme, lang);
    }
  }

  Widget _buildMarketTypeChooser(ThemeData theme, String lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                AppStrings.get('choose_market_step', lang),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.get('choose_market_title', lang),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.get('choose_market_desc', lang),
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: 24),

        // CARD 1: CRYPTO MARKET
        _buildMarketCard(
          theme: theme,
          icon: Icons.bolt_rounded,
          iconBg: theme.colorScheme.primary.withValues(alpha: 0.15),
          iconColor: theme.colorScheme.primary,
          borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
          badgeText: AppStrings.get('crypto_market_badge', lang),
          title: AppStrings.get('crypto_market_title', lang),
          description: AppStrings.get('crypto_market_desc', lang),
          tags: ['Binance', 'Nobitex', 'KuCoin', 'Wallex', 'CoinGecko'],
          buttonText: AppStrings.get('crypto_market_cta', lang),
          buttonColor: theme.colorScheme.primary,
          onTap: () {
            setState(() {
              _flowType = MarketFlowType.crypto;
              _step = 1;
            });
          },
        ),

        const SizedBox(height: 18),

        // CARD 2: US STOCKS, BONDS & FOREX
        _buildMarketCard(
          theme: theme,
          icon: Icons.account_balance_rounded,
          iconBg: theme.colorScheme.secondary.withValues(alpha: 0.15),
          iconColor: theme.colorScheme.secondary,
          borderColor: theme.colorScheme.secondary.withValues(alpha: 0.35),
          badgeText: AppStrings.get('macro_market_badge', lang),
          title: AppStrings.get('macro_market_title', lang),
          description: AppStrings.get('macro_market_desc', lang),
          tags: ['US10Y', 'EUR/USD', 'NVDA', 'Gold (XAU)', 'S&P 500'],
          buttonText: AppStrings.get('macro_market_cta', lang),
          buttonColor: theme.colorScheme.secondary,
          onTap: () {
            setState(() {
              _flowType = MarketFlowType.macro;
              _step = 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMarketCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    required String badgeText,
    required String title,
    required String description,
    required List<String> tags,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: buttonColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: buttonColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: buttonColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: buttonColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonText,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: buttonColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoExchangePicker(ThemeData theme, String lang) {
    final allExchanges = widget.registry.getAll();
    final filtered = allExchanges.where((ex) {
      if (_selectedCategory != ExchangeCategory.all && ex.category != _selectedCategory) {
        return false;
      }
      final q = _exchangeSearchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return ex.name.toLowerCase().contains(q) ||
          ex.id.toLowerCase().contains(q) ||
          ex.countryBadge.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _exchangeSearchQuery = val),
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: AppStrings.get('search_exchange_hint', lang),
              prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ExchangeCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('${cat.icon} ${cat.titleFa}'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ex = filtered[index];
              return InkWell(
                onTap: () => _onExchangeChosen(ex),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ex.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                              '${ex.countryBadge} · ${ex.defaultCounterCurrency}',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoPairPicker(ThemeData theme, String lang) {
    final filtered = _exchangePairs.where((p) {
      final q = _pairSearchQuery.trim().toUpperCase();
      if (q.isEmpty) return true;
      return p.baseCurrency.toUpperCase().contains(q) ||
          p.counterCurrency.toUpperCase().contains(q) ||
          p.marketSymbol.toUpperCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${AppStrings.get('exchange', lang)}: ${_selectedExchange?.name} (${_exchangePairs.length} ${AppStrings.get('pair', lang)})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoadingPairs ? null : () => _fetchPairsForSelectedExchange(forceRefresh: true),
                  icon: _isLoadingPairs
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync_rounded, size: 14),
                  label: Text(AppStrings.get('refresh_list', lang), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (val) => setState(() => _pairSearchQuery = val),
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: AppStrings.get('search_crypto_hint', lang),
              prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: _isLoadingPairs
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pair = filtered[index];
                    return InkWell(
                      onTap: () => _onPairChosen(pair),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            CryptoIcons.buildLogo(pair.baseCurrency, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pair.displayName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                              ),
                            ),
                            Text(
                              AppStrings.get('select_cta', lang),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMacroAssetPicker(ThemeData theme, String lang) {
    final allAssets = GlobalStocksExchange.predefinedStocks;
    final filtered = allAssets.where((a) {
      if (_macroCategoryFilter != 'all') {
        if (_macroCategoryFilter == 'bonds' && a['cat'] != 'Bonds') return false;
        if (_macroCategoryFilter == 'forex' && a['cat'] != 'Forex') return false;
        if (_macroCategoryFilter == 'metals' && a['cat'] != 'Metals') return false;
        if (_macroCategoryFilter == 'stocks' && a['cat'] != 'Tech' && a['cat'] != 'Finance') return false;
        if (_macroCategoryFilter == 'index' && a['cat'] != 'Index') return false;
      }
      final q = _macroSearchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final sym = (a['symbol'] as String).toLowerCase();
      final name = (a['name'] as String).toLowerCase();
      final nameFa = (a['nameFa'] as String).toLowerCase();
      return sym.contains(q) || name.contains(q) || nameFa.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _macroSearchQuery = val),
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: AppStrings.get('search_macro_hint', lang),
              prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildMacroChip(AppStrings.get('all_symbols', lang), 'all', theme),
              _buildMacroChip(AppStrings.get('us_bonds', lang), 'bonds', theme),
              _buildMacroChip(AppStrings.get('forex_pairs', lang), 'forex', theme),
              _buildMacroChip(AppStrings.get('gold_metals', lang), 'metals', theme),
              _buildMacroChip(AppStrings.get('wallstreet_stocks', lang), 'stocks', theme),
              _buildMacroChip(AppStrings.get('global_indices', lang), 'index', theme),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final asset = filtered[index];
              final price = (asset['price'] as num).toDouble();
              final isFa = lang == 'fa' || lang == 'ar' || lang == 'ckb';
              final displayName = isFa ? (asset['nameFa'] as String) : (asset['name'] as String);

              return InkWell(
                onTap: () => _onMacroAssetChosen(asset),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.show_chart_rounded, color: theme.colorScheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${asset['symbol']} · ${asset['cat']}',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(price < 5 ? 4 : 2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            AppStrings.get('select_cta', lang),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMacroChip(String label, String catKey, ThemeData theme) {
    final isSelected = _macroCategoryFilter == catKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(color: isSelected ? theme.colorScheme.secondary : theme.dividerColor),
        onSelected: (_) => setState(() => _macroCategoryFilter = catKey),
      ),
    );
  }

  Widget _buildConditionAndFrequencyStep(ThemeData theme, String lang) {
    final isFa = lang == 'fa' || lang == 'ar' || lang == 'ckb';
    final assetName = _flowType == MarketFlowType.crypto
        ? _selectedPair?.displayName ?? ''
        : (isFa ? _selectedMacroAsset?['nameFa'] : _selectedMacroAsset?['name']) ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('selected_asset', lang),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                    Text(
                      assetName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              if (_currentPrice != null)
                Text(
                  '\$${_currentPrice!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. FREQUENCY SECTION
        Text(
          AppStrings.get('auto_check_schedule', lang),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _unitValueController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.get('unit_count', lang),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<CheckUnit>(
                value: _checkUnit,
                decoration: InputDecoration(
                  labelText: AppStrings.get('time_unit', lang),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                ),
                items: [
                  DropdownMenuItem(value: CheckUnit.seconds, child: Text(AppStrings.get('seconds', lang))),
                  DropdownMenuItem(value: CheckUnit.minutes, child: Text(AppStrings.get('minutes', lang))),
                  DropdownMenuItem(value: CheckUnit.hours, child: Text(AppStrings.get('hours', lang))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _checkUnit = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.get('interval_prefix', lang)}${_formatCalculatedInterval(lang)}${AppStrings.get('interval_suffix', lang)}',
          style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 2. CONDITION TYPE
        Text(
          AppStrings.get('condition_type', lang),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _conditionType = AlertConditionType.percentChange),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _conditionType == AlertConditionType.percentChange
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _conditionType == AlertConditionType.percentChange
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.get('percent_change', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _conditionType == AlertConditionType.percentChange
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _conditionType = AlertConditionType.priceThreshold),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _conditionType == AlertConditionType.priceThreshold
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _conditionType == AlertConditionType.priceThreshold
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.get('price_target', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _conditionType == AlertConditionType.priceThreshold
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_conditionType == AlertConditionType.percentChange) ...[
          Text(
            AppStrings.get('price_direction', lang),
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDirectionChip(AppStrings.get('both_ways', lang), AlertDirection.bothSides, theme),
              const SizedBox(width: 8),
              _buildDirectionChip(AppStrings.get('above_only', lang), AlertDirection.above, theme),
              const SizedBox(width: 8),
              _buildDirectionChip(AppStrings.get('below_only', lang), AlertDirection.below, theme),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _percentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: AppStrings.get('percent_label', lang),
              hintText: '2.5',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
          ),
        ],

        if (_conditionType == AlertConditionType.priceThreshold) ...[
          Text(
            AppStrings.get('price_cross_direction', lang),
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDirectionChip(AppStrings.get('above_target', lang), AlertDirection.above, theme),
              const SizedBox(width: 8),
              _buildDirectionChip(AppStrings.get('below_target', lang), AlertDirection.below, theme),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: AppStrings.get('target_price_label', lang),
              hintText: '95000',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveAlert(lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppStrings.get('save_alert_cta', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionChip(String label, AlertDirection dir, ThemeData theme) {
    final isSelected = _direction == dir;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _direction = dir),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

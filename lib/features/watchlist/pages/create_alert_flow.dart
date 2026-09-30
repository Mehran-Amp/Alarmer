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

/// BitcoinChecker-style Professional Alert Creator.
/// First Step: 2 Big Beautiful Market Cards (Crypto vs US Stocks/Bonds/Forex).
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
  String _macroCategoryFilter = 'all'; // all, bonds, forex, stocks, commodities, indices
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
        return (value * 60).clamp(1, 86400);
      case CheckUnit.hours:
        return (value * 3600).clamp(1, 86400);
    }
  }

  String _formatCalculatedInterval() {
    final value = int.tryParse(_unitValueController.text.trim()) ?? 1;
    switch (_checkUnit) {
      case CheckUnit.seconds:
        return '$value ثانیه';
      case CheckUnit.minutes:
        return '$value دقیقه';
      case CheckUnit.hours:
        return '$value ساعت';
    }
  }

  Future<void> _onExchangeChosen(Exchange exchange) async {
    setState(() {
      _selectedExchange = exchange;
      _step = 2;
      _isLoadingPairs = true;
      _pairSearchQuery = '';
      _selectedPair = null;
    });

    await _fetchPairsForSelectedExchange(forceRefresh: false);
  }

  Future<void> _fetchPairsForSelectedExchange({bool forceRefresh = false}) async {
    if (_selectedExchange == null) return;
    setState(() => _isLoadingPairs = true);

    try {
      final pairs = forceRefresh
          ? await widget.registry.refreshCurrencyPairs(_selectedExchange!.id)
          : await widget.registry.getCurrencyPairs(_selectedExchange!.id);

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

  Future<void> _saveAlert() async {
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
          const SnackBar(content: Text('لطفاً قیمت هدف را وارد کنید')),
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
          icon: const Icon(Icons.arrow_back_rounded),
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
      body: _buildCurrentBody(),
    );
  }

  Widget _buildCurrentBody() {
    if (_flowType == MarketFlowType.none) {
      return _buildMarketTypeChooser();
    } else if (_flowType == MarketFlowType.crypto) {
      if (_step == 1) return _buildCryptoExchangePicker();
      if (_step == 2) return _buildCryptoPairPicker();
      return _buildConditionAndFrequencyStep();
    } else {
      if (_step == 1) return _buildMacroAssetPicker();
      return _buildConditionAndFrequencyStep();
    }
  }

  // ==========================================
  // SCREEN 0: TWO BIG PROMINENT MARKET BUTTONS
  // ==========================================
  Widget _buildMarketTypeChooser() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTokens.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppTokens.primary),
              SizedBox(width: 6),
              Text(
                'گام نخست: انتخاب نوع بازار',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'مایلید برای کدام بازار هشدار تنظیم کنید؟',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'نوع بازار و دارایی مورد نظر خود را برای پایش دقیق قیمت انتخاب نمایید.',
          style: TextStyle(fontSize: 12, color: AppTokens.textSecondary),
        ),
        const SizedBox(height: 24),

        // CARD 1: CRYPTO MARKET (⚡ بازار رمزارزها)
        _buildMarketCard(
          icon: Icons.bolt_rounded,
          iconBg: const Color(0xFF10B981).withValues(alpha: 0.15),
          iconColor: const Color(0xFF10B981),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.4),
          badgeText: 'بیش از ۴۰ صرافی معتبر',
          title: '⚡ بازار رمزارزها (کریپتو)',
          description:
              'بیش از ۴۰ صرافی معتبر بین‌المللی و ایرانی با چیپ‌های فیلتر، استخراج جفت‌ارزها و دکمه بروزرسانی',
          tags: ['بایننس', 'نوبیتکس', 'کوکوین', 'والکس', 'CoinGecko'],
          buttonText: 'ورود به بخش صرافی‌های کریپتو ←',
          buttonColor: const Color(0xFF10B981),
          onTap: () {
            setState(() {
              _flowType = MarketFlowType.crypto;
              _step = 1;
            });
          },
        ),

        const SizedBox(height: 18),

        // CARD 2: US STOCKS, BONDS & FOREX (🏛️ سهام، اوراق قرضه آمریکا و فارکس)
        _buildMarketCard(
          icon: Icons.account_balance_rounded,
          iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          iconColor: const Color(0xFF3B82F6),
          borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
          badgeText: 'وال استریت و اقتصاد کلان',
          title: '🏛️ سهام، اوراق قرضه آمریکا و فارکس',
          description:
              'اوراق قرضه ۱۰ ساله آمریکا (US10Y)، جفت‌ارزهای فارکس، سهام‌های نزدک/نیویورک، طلا و شاخص‌ها',
          tags: ['اوراق US10Y', 'یورو/دلار', 'سهام انویدیا و اپل', 'انس طلا'],
          buttonText: 'ورود به بازارهای جهانی ←',
          buttonColor: const Color(0xFF3B82F6),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.1),
              blurRadius: 16,
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
                    color: AppTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTokens.borderSubtle),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTokens.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t, style: const TextStyle(fontSize: 10, color: AppTokens.textMuted)),
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

  // ==========================================
  // CRYPTO FLOW: STEP 1 (EXCHANGES LIST)
  // ==========================================
  Widget _buildCryptoExchangePicker() {
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
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'جستجوی صرافی (Binance, Nobitex, Wallex, KuCoin, OKX)...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    color: isSelected ? AppTokens.primary : AppTokens.textSecondary,
                  ),
                  selectedColor: AppTokens.primary.withValues(alpha: 0.15),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(color: isSelected ? AppTokens.primary : AppTokens.borderSubtle),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTokens.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTokens.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ex.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTokens.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${ex.countryBadge} · جفت‌ارز مبنا: ${ex.defaultCounterCurrency}',
                                style: const TextStyle(fontSize: 11, color: AppTokens.textMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTokens.textMuted),
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

  // ==========================================
  // CRYPTO FLOW: STEP 2 (PAIRS LIST)
  // ==========================================
  Widget _buildCryptoPairPicker() {
    final filtered = _exchangePairs.where((p) {
      final q = _pairSearchQuery.trim().toUpperCase();
      if (q.isEmpty) return true;
      return p.baseCurrency.toUpperCase().contains(q) ||
          p.counterCurrency.toUpperCase().contains(q) ||
          p.marketSymbol.toUpperCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Header with sync button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTokens.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'صرافی: ${_selectedExchange?.name} (${_exchangePairs.length} جفت‌ارز)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoadingPairs ? null : () => _fetchPairsForSelectedExchange(forceRefresh: true),
                  icon: _isLoadingPairs
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded, size: 14),
                  label: const Text('بروزرسانی لیست', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primary,
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
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'جستجوی رمزارز (BTC, ETH, SOL, POL, DOGE, PEPE)...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: _isLoadingPairs
              ? const Center(child: CircularProgressIndicator())
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTokens.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            CryptoIcons.buildLogo(pair.baseCurrency, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pair.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const Text(
                              'انتخاب →',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.primary),
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

  // ==========================================
  // MACRO FLOW: STEP 1 (BONDS, FOREX, STOCKS)
  // ==========================================
  Widget _buildMacroAssetPicker() {
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
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'جستجوی نماد (US10Y, EUR/USD, NVDA, طلا, S&P 500)...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              {'id': 'all', 'label': '🌐 همه'},
              {'id': 'bonds', 'label': '🏛️ اوراق قرضه آمریکا'},
              {'id': 'forex', 'label': '💱 فارکس'},
              {'id': 'metals', 'label': '🪙 طلا و کالاها'},
              {'id': 'stocks', 'label': '📈 سهام‌های برتر آمریکا'},
              {'id': 'index', 'label': '📊 شاخص‌های جهانی'},
            ].map((cat) {
              final isSelected = _macroCategoryFilter == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(cat['label']!),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF3B82F6) : AppTokens.textSecondary,
                  ),
                  selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF3B82F6) : AppTokens.borderSubtle,
                  ),
                  onSelected: (_) => setState(() => _macroCategoryFilter = cat['id']!),
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
              final asset = filtered[index];
              final price = (asset['price'] as num).toDouble();
              return InkWell(
                onTap: () => _onMacroAssetChosen(asset),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTokens.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.show_chart_rounded, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset['nameFa'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${asset['symbol']} · دسته: ${asset['cat']}',
                                style: const TextStyle(fontSize: 11, color: AppTokens.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(price < 5 ? 4 : 2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                          ),
                          const Text(
                            'انتخاب →',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
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

  // ==========================================
  // FINAL STEP: FREQUENCY & CONDITION SETTINGS
  // ==========================================
  Widget _buildConditionAndFrequencyStep() {
    final assetName = _flowType == MarketFlowType.crypto
        ? _selectedPair?.displayName ?? ''
        : _selectedMacroAsset?['nameFa'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Target asset header badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTokens.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTokens.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('دارایی انتخاب‌شده:', style: TextStyle(fontSize: 11, color: AppTokens.textMuted)),
                    Text(assetName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_currentPrice != null)
                Text(
                  '\$${_currentPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. FREQUENCY SECTION
        const Text('۱. زمان‌بندی بررسی خودکار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _unitValueController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'تعداد واحد',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                  labelText: 'واحد زمان',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: CheckUnit.seconds, child: Text('ثانیه')),
                  DropdownMenuItem(value: CheckUnit.minutes, child: Text('دقیقه')),
                  DropdownMenuItem(value: CheckUnit.hours, child: Text('ساعت')),
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
          '⏱️ بررسی قیمت هر ${_formatCalculatedInterval()} یک‌بار در پس‌زمینه انجام خواهد شد.',
          style: const TextStyle(fontSize: 11, color: AppTokens.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 2. CONDITION TYPE
        const Text('۲. نوع شرط هشدار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        ? AppTokens.primary.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _conditionType == AlertConditionType.percentChange
                          ? AppTokens.primary
                          : AppTokens.borderSubtle,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'درصد تغییر (%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _conditionType == AlertConditionType.percentChange
                          ? AppTokens.primary
                          : AppTokens.textSecondary,
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
                        ? AppTokens.primary.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _conditionType == AlertConditionType.priceThreshold
                          ? AppTokens.primary
                          : AppTokens.borderSubtle,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    r'قیمت هدف ($)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _conditionType == AlertConditionType.priceThreshold
                          ? AppTokens.primary
                          : AppTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_conditionType == AlertConditionType.percentChange) ...[
          const Text('جهت نوسان قیمت:', style: TextStyle(fontSize: 12, color: AppTokens.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDirectionChip('± هر دو طرف', AlertDirection.bothSides),
              const SizedBox(width: 8),
              _buildDirectionChip('▲ فقط افزایش', AlertDirection.above),
              const SizedBox(width: 8),
              _buildDirectionChip('▼ فقط کاهش', AlertDirection.below),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _percentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'درصد نوسان مد نظر (%)',
              hintText: 'مثال: 2.5',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],

        if (_conditionType == AlertConditionType.priceThreshold) ...[
          const Text('جهت عبور قیمت:', style: TextStyle(fontSize: 12, color: AppTokens.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDirectionChip('▲ بالاتر از هدف', AlertDirection.above),
              const SizedBox(width: 8),
              _buildDirectionChip('▼ پایین‌تر از هدف', AlertDirection.below),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'قیمت هدف (دلار)',
              hintText: 'مثال: 95000',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ذخیره و شروع بررسی هشدار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionChip(String label, AlertDirection dir) {
    final isSelected = _direction == dir;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _direction = dir),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.primary : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTokens.primary : AppTokens.borderSubtle),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

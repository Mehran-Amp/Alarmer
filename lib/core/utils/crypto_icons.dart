import 'package:flutter/material.dart';

/// Helper utility for authentic cryptocurrency logos, global stocks, US bonds,
/// commodities, forex, and brand colors.
class CryptoIcons {
  // Built-in verified high-resolution icon mapping
  static const Map<String, _AssetMeta> _metadata = {
    // 1. TOP CRYPTOCURRENCIES
    'BTC': _AssetMeta('Bitcoin', Color(0xFFF7931A), 'https://assets.coingecko.com/coins/images/1/small/bitcoin.png'),
    'ETH': _AssetMeta('Ethereum', Color(0xFF627EEA), 'https://assets.coingecko.com/coins/images/279/small/ethereum.png'),
    'SOL': _AssetMeta('Solana', Color(0xFF14F195), 'https://assets.coingecko.com/coins/images/4128/small/solana.png'),
    'BNB': _AssetMeta('BNB', Color(0xFFF3BA2F), 'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png'),
    'XRP': _AssetMeta('XRP', Color(0xFF23292F), 'https://assets.coingecko.com/coins/images/44/small/xrp-symbol-white-128.png'),
    'DOGE': _AssetMeta('Dogecoin', Color(0xFFC2A633), 'https://assets.coingecko.com/coins/images/5/small/dogecoin.png'),
    'ADA': _AssetMeta('Cardano', Color(0xFF0033AD), 'https://assets.coingecko.com/coins/images/975/small/cardano.png'),
    'AVAX': _AssetMeta('Avalanche', Color(0xFFE84142), 'https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png'),
    'DOT': _AssetMeta('Polkadot', Color(0xFFE6007A), 'https://assets.coingecko.com/coins/images/12171/small/polkadot.png'),
    'POL': _AssetMeta('Polygon (POL)', Color(0xFF8247E5), 'https://assets.coingecko.com/coins/images/4713/small/polygon.png'),
    'MATIC': _AssetMeta('Polygon (POL)', Color(0xFF8247E5), 'https://assets.coingecko.com/coins/images/4713/small/polygon.png'),
    'RENDER': _AssetMeta('Render', Color(0xFFE53935), 'https://assets.coingecko.com/coins/images/11636/small/rndr.png'),
    'RNDR': _AssetMeta('Render', Color(0xFFE53935), 'https://assets.coingecko.com/coins/images/11636/small/rndr.png'),
    'S': _AssetMeta('Sonic (S)', Color(0xFF1969FF), 'https://assets.coingecko.com/coins/images/4001/small/Fantom_round.png'),
    'FTM': _AssetMeta('Sonic (S)', Color(0xFF1969FF), 'https://assets.coingecko.com/coins/images/4001/small/Fantom_round.png'),
    'SKY': _AssetMeta('Sky (Maker)', Color(0xFF1AAB9B), 'https://assets.coingecko.com/coins/images/1364/small/Mark_Maker.png'),
    'MKR': _AssetMeta('Sky (Maker)', Color(0xFF1AAB9B), 'https://assets.coingecko.com/coins/images/1364/small/Mark_Maker.png'),
    'FET': _AssetMeta('Artificial Superintelligence Alliance', Color(0xFF1B2430), 'https://assets.coingecko.com/coins/images/5681/small/Fetch.jpg'),
    'BEAM': _AssetMeta('Beam', Color(0xFF2CD5C4), 'https://assets.coingecko.com/coins/images/32417/small/beam-logo.png'),
    'LUNC': _AssetMeta('Terra Classic', Color(0xFFFFD83D), 'https://assets.coingecko.com/coins/images/8284/small/luna1557227471663.png'),
    'LUNA': _AssetMeta('Terra 2.0', Color(0xFFFFD83D), 'https://assets.coingecko.com/coins/images/25767/small/01_LunaToken_Round.png'),
    'TON': _AssetMeta('Toncoin', Color(0xFF0098EA), 'https://assets.coingecko.com/coins/images/17980/small/ton_symbol.png'),
    'SUI': _AssetMeta('Sui', Color(0xFF2A82E4), 'https://assets.coingecko.com/coins/images/26375/small/sui-ocean-square.png'),
    'PEPE': _AssetMeta('Pepe', Color(0xFF539F37), 'https://assets.coingecko.com/coins/images/29850/small/pepe-token.png'),
    'WIF': _AssetMeta('dogwifhat', Color(0xFFAB7C5F), 'https://assets.coingecko.com/coins/images/33566/small/dogwifhat.jpg'),
    'BONK': _AssetMeta('Bonk', Color(0xFFFF9500), 'https://assets.coingecko.com/coins/images/28600/small/bonk.jpg'),
    'FLOKI': _AssetMeta('Floki', Color(0xFFEAA428), 'https://assets.coingecko.com/coins/images/16746/small/FLOKI.png'),
    'SHIB': _AssetMeta('Shiba Inu', Color(0xFFFFA409), 'https://assets.coingecko.com/coins/images/11939/small/shiba.png'),
    'TAO': _AssetMeta('Bittensor', Color(0xFF262626), 'https://assets.coingecko.com/coins/images/28452/small/bittensor_logo.png'),
    'KAS': _AssetMeta('Kaspa', Color(0xFF70C7BA), 'https://assets.coingecko.com/coins/images/28898/small/kaspa.png'),
    'NEAR': _AssetMeta('NEAR Protocol', Color(0xFF000000), 'https://assets.coingecko.com/coins/images/10365/small/near.png'),
    'APT': _AssetMeta('Aptos', Color(0xFF14B8A6), 'https://assets.coingecko.com/coins/images/26455/small/aptos_round.png'),
    'LINK': _AssetMeta('Chainlink', Color(0xFF375BD2), 'https://assets.coingecko.com/coins/images/877/small/chainlink-new-logo.png'),
    'TRX': _AssetMeta('TRON', Color(0xFFFF0013), 'https://assets.coingecko.com/coins/images/1094/small/tron-logo.png'),
    'LTC': _AssetMeta('Litecoin', Color(0xFF345D9D), 'https://assets.coingecko.com/coins/images/2/small/litecoin.png'),
    'BCH': _AssetMeta('Bitcoin Cash', Color(0xFF8DC351), 'https://assets.coingecko.com/coins/images/780/small/bitcoin-cash-circle.png'),
    'UNI': _AssetMeta('Uniswap', Color(0xFFFF007A), 'https://assets.coingecko.com/coins/images/12504/small/uniswap-uni.png'),
    'ATOM': _AssetMeta('Cosmos', Color(0xFF2E3148), 'https://assets.coingecko.com/coins/images/1481/small/cosmos_hub.png'),
    'TIA': _AssetMeta('Celestia', Color(0xFF7B2CBF), 'https://assets.coingecko.com/coins/images/31967/small/celestia.png'),
    'SEI': _AssetMeta('Sei', Color(0xFF9013FE), 'https://assets.coingecko.com/coins/images/28205/small/Sei_Logo_-_Transparent.png'),
    'INJ': _AssetMeta('Injective', Color(0xFF00B2FF), 'https://assets.coingecko.com/coins/images/12882/small/Secondary_Symbol.png'),
    'XLM': _AssetMeta('Stellar', Color(0xFF14B6EB), 'https://assets.coingecko.com/coins/images/100/small/Stellar_symbol_black_RGB.png'),
    'ALGO': _AssetMeta('Algorand', Color(0xFF000000), 'https://assets.coingecko.com/coins/images/4380/small/download.png'),
    'ICP': _AssetMeta('Internet Computer', Color(0xFF29ABE2), 'https://assets.coingecko.com/coins/images/14495/small/Internet_Computer_logo.png'),
    'FIL': _AssetMeta('Filecoin', Color(0xFF0090FF), 'https://assets.coingecko.com/coins/images/12817/small/filecoin.png'),
    'ARB': _AssetMeta('Arbitrum', Color(0xFF28A0F0), 'https://assets.coingecko.com/coins/images/16547/small/arbitrum_logo.png'),
    'OP': _AssetMeta('Optimism', Color(0xFFFF0420), 'https://assets.coingecko.com/coins/images/25244/small/Optimism.png'),
    'AAVE': _AssetMeta('Aave', Color(0xFFB6509E), 'https://assets.coingecko.com/coins/images/12645/small/AAVE.png'),
    'SAND': _AssetMeta('The Sandbox', Color(0xFF0084FF), 'https://assets.coingecko.com/coins/images/12129/small/sandbox_logo.jpg'),
    'MANA': _AssetMeta('Decentraland', Color(0xFFFF2D55), 'https://assets.coingecko.com/coins/images/878/small/decentraland-mana.png'),
    'GALA': _AssetMeta('Gala', Color(0xFF1A1A1A), 'https://assets.coingecko.com/coins/images/12493/small/GALA-COINGECKO.png'),
    'CHZ': _AssetMeta('Chiliz', Color(0xFFCD0124), 'https://assets.coingecko.com/coins/images/8834/small/Chiliz.png'),
    'CRV': _AssetMeta('Curve DAO', Color(0xFF0038FF), 'https://assets.coingecko.com/coins/images/12124/small/Curve.png'),
    'AXS': _AssetMeta('Axie Infinity', Color(0xFF0055D5), 'https://assets.coingecko.com/coins/images/13029/small/axie_infinity_logo.png'),
    'DYDX': _AssetMeta('dYdX', Color(0xFF6966FF), 'https://assets.coingecko.com/coins/images/17500/small/hjnIm9bV.jpg'),
    '1INCH': _AssetMeta('1inch', Color(0xFF1B314F), 'https://assets.coingecko.com/coins/images/13469/small/1inch-token.png'),
    'LDO': _AssetMeta('Lido DAO', Color(0xFF00A3FF), 'https://assets.coingecko.com/coins/images/13573/small/Lido_DAO.png'),
    'GRT': _AssetMeta('The Graph', Color(0xFF6747ED), 'https://assets.coingecko.com/coins/images/13397/small/Graph_Token.png'),
    'STX': _AssetMeta('Stacks', Color(0xFF5546FF), 'https://assets.coingecko.com/coins/images/2069/small/Stacks_Logo_png.png'),
    'RUNE': _AssetMeta('THORChain', Color(0xFF00CCFF), 'https://assets.coingecko.com/coins/images/6595/small/thorchain.png'),
    'THETA': _AssetMeta('Theta Network', Color(0xFF2AB8E6), 'https://assets.coingecko.com/coins/images/2538/small/theta-token-logo.png'),
    'EOS': _AssetMeta('EOS', Color(0xFF191919), 'https://assets.coingecko.com/coins/images/738/small/eos-eos-logo.png'),
    'FLOW': _AssetMeta('Flow', Color(0xFF00EF8B), 'https://assets.coingecko.com/coins/images/13446/small/5f6294c0c7a8cda55d1c4ab8_flow-icon.png'),
    'XMR': _AssetMeta('Monero', Color(0xFFFF6600), 'https://assets.coingecko.com/coins/images/69/small/monero_logo.png'),
    'ZEC': _AssetMeta('Zcash', Color(0xFFF4B728), 'https://assets.coingecko.com/coins/images/486/small/circle-zcash-color.png'),
    'DASH': _AssetMeta('Dash', Color(0xFF008CE7), 'https://assets.coingecko.com/coins/images/19/small/dash-logo.png'),
    'NEO': _AssetMeta('NEO', Color(0xFF58BF00), 'https://assets.coingecko.com/coins/images/480/small/NEO_512_512.png'),
    'IOTA': _AssetMeta('IOTA', Color(0xFF242424), 'https://assets.coingecko.com/coins/images/692/small/IOTA_Swirl.png'),
    'KAVA': _AssetMeta('Kava', Color(0xFFFF564F), 'https://assets.coingecko.com/coins/images/9761/small/kava.png'),
    'SNX': _AssetMeta('Synthetix', Color(0xFF00D1FF), 'https://assets.coingecko.com/coins/images/3406/small/SNX.png'),
    'COMP': _AssetMeta('Compound', Color(0xFF00D395), 'https://assets.coingecko.com/coins/images/10775/small/COMP.png'),
    'BAT': _AssetMeta('Basic Attention Token', Color(0xFFFF5000), 'https://assets.coingecko.com/coins/images/677/small/basic-attention-token.png'),
    'ZIL': _AssetMeta('Zilliqa', Color(0xFF29CCC4), 'https://assets.coingecko.com/coins/images/2687/small/Zilliqa-logo.png'),
    'YFI': _AssetMeta('yearn.finance', Color(0xFF006AE3), 'https://assets.coingecko.com/coins/images/11849/small/yearn-finance-logo.png'),
    'SUSHI': _AssetMeta('Sushi', Color(0xFFFA52A0), 'https://assets.coingecko.com/coins/images/12271/small/512x512_Logo_no_chop.png'),
    'USDT': _AssetMeta('Tether', Color(0xFF26A17B), 'https://assets.coingecko.com/coins/images/325/small/Tether.png'),
    'USDC': _AssetMeta('USDC', Color(0xFF2775CA), 'https://assets.coingecko.com/coins/images/6319/small/usdc.png'),
    'DAI': _AssetMeta('Dai', Color(0xFFF5AC37), 'https://assets.coingecko.com/coins/images/9956/small/Badge_Dai.png'),
    'FDUSD': _AssetMeta('First Digital USD', Color(0xFF0038FF), 'https://assets.coingecko.com/coins/images/31079/small/First_Digital_USD.png'),

    // 2. US TREASURY BONDS & YIELDS
    '^TNX': _AssetMeta('US 10-Year Treasury Yield', Color(0xFF10B981), '', customIcon: Icons.account_balance_rounded),
    'US10Y': _AssetMeta('US 10-Year Treasury Yield', Color(0xFF10B981), '', customIcon: Icons.account_balance_rounded),
    '^IRX': _AssetMeta('US 2-Year Treasury Yield', Color(0xFF3B82F6), '', customIcon: Icons.account_balance_rounded),
    'US02Y': _AssetMeta('US 2-Year Treasury Yield', Color(0xFF3B82F6), '', customIcon: Icons.account_balance_rounded),
    '^TYX': _AssetMeta('US 30-Year Treasury Bond', Color(0xFF8B5CF6), '', customIcon: Icons.account_balance_rounded),
    'US30Y': _AssetMeta('US 30-Year Treasury Bond', Color(0xFF8B5CF6), '', customIcon: Icons.account_balance_rounded),

    // 3. COMMODITIES & METALS
    'GC=F': _AssetMeta('Gold (XAU/USD)', Color(0xFFFFD700), '', customIcon: Icons.monetization_on_rounded),
    'XAU': _AssetMeta('Gold (XAU/USD)', Color(0xFFFFD700), '', customIcon: Icons.monetization_on_rounded),
    'SI=F': _AssetMeta('Silver (XAG/USD)', Color(0xFFC0C0C0), '', customIcon: Icons.circle_rounded),
    'XAG': _AssetMeta('Silver (XAG/USD)', Color(0xFFC0C0C0), '', customIcon: Icons.circle_rounded),
    'CL=F': _AssetMeta('Crude Oil WTI', Color(0xFF1F2937), '', customIcon: Icons.local_gas_station_rounded),
    'BZ=F': _AssetMeta('Brent Crude Oil', Color(0xFF111827), '', customIcon: Icons.water_drop_rounded),
    'NG=F': _AssetMeta('Natural Gas', Color(0xFF0284C7), '', customIcon: Icons.local_fire_department_rounded),
    'HG=F': _AssetMeta('Copper Futures', Color(0xFFB45309), '', customIcon: Icons.layers_rounded),

    // 4. FOREX MAJOR PAIRS
    'EURUSD=X': _AssetMeta('EUR/USD', Color(0xFF003399), '', customIcon: Icons.euro_symbol_rounded),
    'EUR': _AssetMeta('Euro', Color(0xFF003399), '', customIcon: Icons.euro_symbol_rounded),
    'GBPUSD=X': _AssetMeta('GBP/USD', Color(0xFFC8102E), '', customIcon: Icons.currency_pound_rounded),
    'GBP': _AssetMeta('British Pound', Color(0xFFC8102E), '', customIcon: Icons.currency_pound_rounded),
    'USDJPY=X': _AssetMeta('USD/JPY', Color(0xFFBC002D), '', customIcon: Icons.currency_yen_rounded),
    'JPY': _AssetMeta('Japanese Yen', Color(0xFFBC002D), '', customIcon: Icons.currency_yen_rounded),

    // 5. GLOBAL INDICES
    '^GSPC': _AssetMeta('S&P 500 Index', Color(0xFF2563EB), '', customIcon: Icons.trending_up_rounded),
    'SPX': _AssetMeta('S&P 500 Index', Color(0xFF2563EB), '', customIcon: Icons.trending_up_rounded),
    '^IXIC': _AssetMeta('NASDAQ Composite', Color(0xFF00A3E0), '', customIcon: Icons.auto_graph_rounded),
    'IXIC': _AssetMeta('NASDAQ Composite', Color(0xFF00A3E0), '', customIcon: Icons.auto_graph_rounded),
    '^DJI': _AssetMeta('Dow Jones Industrial', Color(0xFFDC2626), '', customIcon: Icons.candlestick_chart_rounded),
    'DJI': _AssetMeta('Dow Jones Industrial', Color(0xFFDC2626), '', customIcon: Icons.candlestick_chart_rounded),
    '^RUT': _AssetMeta('Russell 2000', Color(0xFF7C3AED), '', customIcon: Icons.bar_chart_rounded),
    '^VIX': _AssetMeta('CBOE Volatility Index', Color(0xFFEA580C), '', customIcon: Icons.speed_rounded),
    'DX-Y.NYB': _AssetMeta('US Dollar Index (DXY)', Color(0xFF059669), '', customIcon: Icons.attach_money_rounded),
    'DXY': _AssetMeta('US Dollar Index (DXY)', Color(0xFF059669), '', customIcon: Icons.attach_money_rounded),

    // 6. TECH & WALL STREET EQUITIES
    'NVDA': _AssetMeta('NVIDIA', Color(0xFF76B900), '', customIcon: Icons.memory_rounded),
    'AAPL': _AssetMeta('Apple', Color(0xFFA2AAAD), '', customIcon: Icons.apple_rounded),
    'MSFT': _AssetMeta('Microsoft', Color(0xFF00A4EF), '', customIcon: Icons.window_rounded),
    'TSLA': _AssetMeta('Tesla', Color(0xFFE82127), '', customIcon: Icons.electric_car_rounded),
    'AMZN': _AssetMeta('Amazon', Color(0xFFFF9900), '', customIcon: Icons.shopping_bag_rounded),
    'GOOGL': _AssetMeta('Google', Color(0xFF4285F4), '', customIcon: Icons.travel_explore_rounded),
    'META': _AssetMeta('Meta', Color(0xFF0668E1), '', customIcon: Icons.all_inclusive_rounded),
    'AVGO': _AssetMeta('Broadcom', Color(0xFFCC092F), '', customIcon: Icons.developer_board_rounded),
    'TSM': _AssetMeta('TSMC', Color(0xFF005596), '', customIcon: Icons.hardware_rounded),
    'AMD': _AssetMeta('AMD', Color(0xFFED1C24), '', customIcon: Icons.memory_rounded),
    'PLTR': _AssetMeta('Palantir', Color(0xFF000000), '', customIcon: Icons.shield_rounded),
    'SMCI': _AssetMeta('Super Micro', Color(0xFF0072CE), '', customIcon: Icons.dns_rounded),
    'ARM': _AssetMeta('Arm', Color(0xFF0091BD), '', customIcon: Icons.memory_rounded),
    'QCOM': _AssetMeta('Qualcomm', Color(0xFF3253DC), '', customIcon: Icons.cell_tower_rounded),
    'INTC': _AssetMeta('Intel', Color(0xFF0071C5), '', customIcon: Icons.memory_rounded),
    'BRK-B': _AssetMeta('Berkshire', Color(0xFF002B49), '', customIcon: Icons.domain_rounded),
    'JPM': _AssetMeta('JPMorgan', Color(0xFF005CB9), '', customIcon: Icons.account_balance_rounded),
    'V': _AssetMeta('Visa', Color(0xFF1A1F71), '', customIcon: Icons.credit_card_rounded),
    'MA': _AssetMeta('Mastercard', Color(0xFFEB001B), '', customIcon: Icons.credit_card_rounded),
    'BAC': _AssetMeta('Bank of America', Color(0xFFE31837), '', customIcon: Icons.account_balance_rounded),
    'GS': _AssetMeta('Goldman Sachs', Color(0xFF7399C6), '', customIcon: Icons.account_balance_rounded),
    'LLY': _AssetMeta('Eli Lilly', Color(0xFFD42E12), '', customIcon: Icons.medication_rounded),
    'WMT': _AssetMeta('Walmart', Color(0xFF0071CE), '', customIcon: Icons.store_rounded),
    'COST': _AssetMeta('Costco', Color(0xFFE31837), '', customIcon: Icons.shopping_cart_rounded),
    'KO': _AssetMeta('Coca-Cola', Color(0xFFF40009), '', customIcon: Icons.local_drink_rounded),
    'PEP': _AssetMeta('PepsiCo', Color(0xFF004B93), '', customIcon: Icons.local_drink_rounded),
    'NFLX': _AssetMeta('Netflix', Color(0xFFE50914), '', customIcon: Icons.movie_rounded),
    'DIS': _AssetMeta('Disney', Color(0xFF113CCF), '', customIcon: Icons.castle_rounded),
  };

  /// Returns official branding color for a coin/asset symbol
  static Color getBrandColor(String symbol) {
    final clean = _cleanSymbol(symbol);
    return _metadata[clean]?.brandColor ?? const Color(0xFF10B981);
  }

  /// Returns official human readable display name
  static String getDisplayName(String symbol) {
    final clean = _cleanSymbol(symbol);
    return _metadata[clean]?.name ?? clean;
  }

  /// Builds a high-fidelity crypto / asset logo widget with multi-tier fallback
  static Widget buildLogo(String symbol, {double size = 36}) {
    final clean = _cleanSymbol(symbol);
    final meta = _metadata[clean] ?? _metadata[symbol.toUpperCase()];
    final color = meta?.brandColor ?? _deriveColor(clean);

    // 1. If meta provides a custom vector icon (for Bonds, Commodities, Indices, Stocks)
    if (meta?.customIcon != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(meta!.customIcon, color: color, size: size * 0.55),
      );
    }

    // 2. If meta provides a verified icon URL
    if (meta != null && meta.iconUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          meta.iconUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(clean, color, size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(clean, color, size);
          },
        ),
      );
    }

    // 3. Fallback to decentralized crypto icons CDN (supports 1000+ coins)
    final cdnUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${clean.toLowerCase()}.png';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        cdnUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(clean, color, size),
      ),
    );
  }

  static Widget _buildFallback(String clean, Color color, double size) {
    final shortName = clean.length > 4 ? clean.substring(0, 3) : clean;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        shortName,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static String _cleanSymbol(String symbol) {
    var s = symbol.trim().toUpperCase();
    if (s.contains('/')) {
      s = s.split('/').first;
    }
    s = s.replaceAll('USDT', '').replaceAll('USDC', '').replaceAll('USD', '').replaceAll('IRT', '');
    return s.isEmpty ? symbol.toUpperCase() : s;
  }

  static Color _deriveColor(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
      const Color(0xFF14B8A6),
    ];
    return colors[hash.abs() % colors.length];
  }
}

class _AssetMeta {
  final String name;
  final Color brandColor;
  final String iconUrl;
  final IconData? customIcon;

  const _AssetMeta(
    this.name,
    this.brandColor,
    this.iconUrl, {
    this.customIcon,
  });
}

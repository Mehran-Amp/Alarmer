enum ExchangeCategory {
  all,
  stocks,
  tier1,
  aggregator,
  middleEast,
  asia,
  europe,
  americas,
}

extension ExchangeCategoryExt on ExchangeCategory {
  String get titleFa {
    switch (this) {
      case ExchangeCategory.all:
        return 'همه بازارها و صرافی‌ها';
      case ExchangeCategory.stocks:
        return '🏛️ بورس و سهام جهانی (NYSE & NASDAQ & Gold)';
      case ExchangeCategory.tier1:
        return 'جهانی رتبه یک (Tier-1)';
      case ExchangeCategory.aggregator:
        return 'اگریگیتورهای جامع';
      case ExchangeCategory.middleEast:
        return 'ایران و خاورمیانه';
      case ExchangeCategory.asia:
        return 'آسیا و شرق دور';
      case ExchangeCategory.europe:
        return 'اروپا';
      case ExchangeCategory.americas:
        return 'آمریکا و سایر';
    }
  }

  String get icon {
    switch (this) {
      case ExchangeCategory.all:
        return '🌐';
      case ExchangeCategory.stocks:
        return '🏛️';
      case ExchangeCategory.tier1:
        return '⭐';
      case ExchangeCategory.aggregator:
        return '📊';
      case ExchangeCategory.middleEast:
        return '🇮🇷';
      case ExchangeCategory.asia:
        return '⛩️';
      case ExchangeCategory.europe:
        return '🇪🇺';
      case ExchangeCategory.americas:
        return '🌎';
    }
  }
}

enum ExchangeCategory {
  all,
  tier1,
  middleEast,
  asia,
  europe,
  americas,
  aggregator,
}

extension ExchangeCategoryExt on ExchangeCategory {
  String get titleFa {
    switch (this) {
      case ExchangeCategory.all:
        return 'همه صرافی‌های کریپتو';
      case ExchangeCategory.tier1:
        return 'جهانی رتبه یک (Tier-1)';
      case ExchangeCategory.middleEast:
        return 'ایران و خاورمیانه';
      case ExchangeCategory.asia:
        return 'آسیا و شرق دور';
      case ExchangeCategory.europe:
        return 'اروپا';
      case ExchangeCategory.americas:
        return 'آمریکا و سایر';
      case ExchangeCategory.aggregator:
        return 'مراجع و شاخص‌های تجمیع';
    }
  }

  String get icon {
    switch (this) {
      case ExchangeCategory.all:
        return '🌐';
      case ExchangeCategory.tier1:
        return '⭐';
      case ExchangeCategory.middleEast:
        return '🇮🇷';
      case ExchangeCategory.asia:
        return '⛩️';
      case ExchangeCategory.europe:
        return '🇪🇺';
      case ExchangeCategory.americas:
        return '🌎';
      case ExchangeCategory.aggregator:
        return '📊';
    }
  }
}

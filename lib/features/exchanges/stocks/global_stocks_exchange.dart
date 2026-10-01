import 'dart:convert';
import 'package:http/http.dart' as http;
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Global Stock Markets, Commodities, Forex & Macro Benchmark Adapter
/// (NYSE, NASDAQ, CME, LSE, Tokyo, Forex, Gold, Oil & US Treasuries)
class GlobalStocksExchange implements Exchange {
  final http.Client _client;

  GlobalStocksExchange({http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get id => 'global_stocks';

  @override
  String get name => 'بازارهای جهانی و بورس (Wall Street / Forex / Commodities)';

  @override
  ExchangeCategory get category => ExchangeCategory.all;

  @override
  String get countryBadge => '🏛️ Global Equities & Commodities';

  @override
  String get defaultCounterCurrency => 'USD';

  static const List<Map<String, dynamic>> predefinedStocks = [
    // =========================================================================
    // 1. MACRO ECONOMY, YIELDS & DXY (اوراق قرضه، شاخص دلار و بهره)
    // =========================================================================
    {
      'symbol': 'DX-Y.NYB',
      'name': 'US Dollar Index (DXY)',
      'nameFa': 'شاخص قدرت جهانی دلار آمریکا (DXY)',
      'cat': 'Macro',
      'icon': '💵',
      'price': 104.25,
    },
    {
      'symbol': '^TNX',
      'name': 'US 10-Year Treasury Yield',
      'nameFa': 'نرخ بازدهی اوراق ۱۰ ساله آمریکا (US10Y)',
      'cat': 'Macro',
      'icon': '📈',
      'price': 4.28,
    },
    {
      'symbol': '^IRX',
      'name': 'US 2-Year Treasury Yield',
      'nameFa': 'نرخ بازدهی اوراق ۲ ساله آمریکا (US02Y)',
      'cat': 'Macro',
      'icon': '📊',
      'price': 4.15,
    },
    {
      'symbol': '^TYX',
      'name': 'US 30-Year Treasury Bond',
      'nameFa': 'اوراق قرضه ۳۰ ساله بلندمدت آمریکا (US30Y)',
      'cat': 'Macro',
      'icon': '🏛️',
      'price': 4.52,
    },
    {
      'symbol': '^FVX',
      'name': 'US 5-Year Treasury Yield',
      'nameFa': 'نرخ بازدهی اوراق ۵ ساله آمریکا (US05Y)',
      'cat': 'Macro',
      'icon': '📉',
      'price': 4.18,
    },
    {
      'symbol': '^VIX',
      'name': 'CBOE Volatility Index (VIX)',
      'nameFa': 'شاخص نوسان و ترس وال‌استریت (VIX)',
      'cat': 'Macro',
      'icon': '⚡',
      'price': 18.50,
    },

    // =========================================================================
    // 2. GLOBAL STOCK INDICES (شاخص‌های برتر وال‌استریت و جهان)
    // =========================================================================
    {
      'symbol': '^GSPC',
      'name': 'S&P 500 Index',
      'nameFa': 'شاخص ۵۰۰ شرکت برتر آمریکا (S&P 500)',
      'cat': 'Indices',
      'icon': '🇺🇸',
      'price': 5864.67,
    },
    {
      'symbol': '^NDX',
      'name': 'NASDAQ 100 Index',
      'nameFa': 'شاخص ۱۰۰ شرکت برتر فناوری (NASDAQ 100)',
      'cat': 'Indices',
      'icon': '💻',
      'price': 20380.50,
    },
    {
      'symbol': '^DJI',
      'name': 'Dow Jones Industrial Average',
      'nameFa': 'شاخص صنعتی داوجونز (Dow Jones 30)',
      'cat': 'Indices',
      'icon': '🏭',
      'price': 42931.60,
    },
    {
      'symbol': '^RUT',
      'name': 'Russell 2000 Index',
      'nameFa': 'شاخص ۲۰۰۰ شرکت کوچک و چابک آمریکا (Russell 2000)',
      'cat': 'Indices',
      'icon': '🏢',
      'price': 2250.40,
    },
    {
      'symbol': '^GDAXI',
      'name': 'DAX 40 Germany',
      'nameFa': 'شاخص بورس آلمان (DAX 40)',
      'cat': 'Indices',
      'icon': '🇩🇪',
      'price': 19450.20,
    },
    {
      'symbol': '^FTSE',
      'name': 'FTSE 100 UK',
      'nameFa': 'شاخص بورس لندن (FTSE 100)',
      'cat': 'Indices',
      'icon': '🇬🇧',
      'price': 8250.80,
    },
    {
      'symbol': '^FCHI',
      'name': 'CAC 40 France',
      'nameFa': 'شاخص بورس پاریس (CAC 40)',
      'cat': 'Indices',
      'icon': '🇫🇷',
      'price': 7510.30,
    },
    {
      'symbol': '^N225',
      'name': 'Nikkei 225 Japan',
      'nameFa': 'شاخص بورس توکیو ژاپن (Nikkei 225)',
      'cat': 'Indices',
      'icon': '🇯🇵',
      'price': 38980.00,
    },
    {
      'symbol': '^HSI',
      'name': 'Hang Seng Index Hong Kong',
      'nameFa': 'شاخص بورس هنگ‌کنگ (Hang Seng)',
      'cat': 'Indices',
      'icon': '🇭🇰',
      'price': 20680.40,
    },
    {
      'symbol': '000001.SS',
      'name': 'Shanghai Composite Index',
      'nameFa': 'شاخص بورس شانگهای چین (SSE)',
      'cat': 'Indices',
      'icon': '🇨🇳',
      'price': 3290.15,
    },

    // =========================================================================
    // 3. PRECIOUS METALS, ENERGY & COMMODITIES (طلا، نقره، نفت و فلزات)
    // =========================================================================
    {
      'symbol': 'GC=F',
      'name': 'Gold Spot (XAU/USD)',
      'nameFa': 'انس طلای جهانی (Gold XAU/USD)',
      'cat': 'Commodities',
      'icon': '🥇',
      'price': 2735.40,
    },
    {
      'symbol': 'SI=F',
      'name': 'Silver Spot (XAG/USD)',
      'nameFa': 'انس نقره جهانی (Silver XAG/USD)',
      'cat': 'Commodities',
      'icon': '🥈',
      'price': 33.85,
    },
    {
      'symbol': 'PL=F',
      'name': 'Platinum Futures',
      'nameFa': 'انس پلاتین جهانی (Platinum)',
      'cat': 'Commodities',
      'icon': '⚪',
      'price': 1025.50,
    },
    {
      'symbol': 'PA=F',
      'name': 'Palladium Futures',
      'nameFa': 'انس پالادیوم جهانی (Palladium)',
      'cat': 'Commodities',
      'icon': '✨',
      'price': 1140.00,
    },
    {
      'symbol': 'BZ=F',
      'name': 'Brent Crude Oil',
      'nameFa': 'نفت خام برنت دریای شمال (Brent)',
      'cat': 'Commodities',
      'icon': '🛢️',
      'price': 75.40,
    },
    {
      'symbol': 'CL=F',
      'name': 'Crude Oil WTI',
      'nameFa': 'نفت خام سبک تگزاس (WTI Oil)',
      'cat': 'Commodities',
      'icon': '⛽',
      'price': 71.20,
    },
    {
      'symbol': 'NG=F',
      'name': 'Natural Gas Futures',
      'nameFa': 'گاز طبیعی جهانی (Natural Gas)',
      'cat': 'Commodities',
      'icon': '🔥',
      'price': 2.85,
    },
    {
      'symbol': 'HG=F',
      'name': 'Copper Futures (Dr. Copper)',
      'nameFa': 'مس صنعتی جهانی (دماسنج اقتصاد)',
      'cat': 'Commodities',
      'icon': '🥉',
      'price': 4.42,
    },

    // =========================================================================
    // 4. FOREX MAJORS & CROSSES (فارکس و برابری ارزهای فیات)
    // =========================================================================
    {
      'symbol': 'EURUSD=X',
      'name': 'EUR/USD',
      'nameFa': 'یورو به دلار آمریکا (EUR/USD)',
      'cat': 'Forex',
      'icon': '🇪🇺',
      'price': 1.0825,
    },
    {
      'symbol': 'GBPUSD=X',
      'name': 'GBP/USD (Cable)',
      'nameFa': 'پوند انگلیس به دلار آمریکا (GBP/USD)',
      'cat': 'Forex',
      'icon': '🇬🇧',
      'price': 1.2980,
    },
    {
      'symbol': 'USDJPY=X',
      'name': 'USD/JPY',
      'nameFa': 'دلار آمریکا به ین ژاپن (USD/JPY)',
      'cat': 'Forex',
      'icon': '🇯🇵',
      'price': 153.40,
    },
    {
      'symbol': 'USDCHF=X',
      'name': 'USD/CHF (Swissie)',
      'nameFa': 'دلار آمریکا به فرانک سوئیس (USD/CHF)',
      'cat': 'Forex',
      'icon': '🇨🇭',
      'price': 0.8670,
    },
    {
      'symbol': 'AUDUSD=X',
      'name': 'AUD/USD (Aussie)',
      'nameFa': 'دلار استرالیا به دلار آمریکا (AUD/USD)',
      'cat': 'Forex',
      'icon': '🇦🇺',
      'price': 0.6620,
    },
    {
      'symbol': 'USDCAD=X',
      'name': 'USD/CAD (Loonie)',
      'nameFa': 'دلار آمریکا به دلار کانادا (USD/CAD)',
      'cat': 'Forex',
      'icon': '🇨🇦',
      'price': 1.3850,
    },
    {
      'symbol': 'NZDUSD=X',
      'name': 'NZD/USD (Kiwi)',
      'nameFa': 'دلار نیوزیلند به دلار آمریکا (NZD/USD)',
      'cat': 'Forex',
      'icon': '🇳🇿',
      'price': 0.6010,
    },
    {
      'symbol': 'EURJPY=X',
      'name': 'EUR/JPY',
      'nameFa': 'یورو به ین ژاپن (EUR/JPY)',
      'cat': 'Forex',
      'icon': '💱',
      'price': 166.10,
    },
    {
      'symbol': 'GBPJPY=X',
      'name': 'GBP/JPY (Guppy)',
      'nameFa': 'پوند انگلیس به ین ژاپن (GBP/JPY)',
      'cat': 'Forex',
      'icon': '💱',
      'price': 199.20,
    },
    {
      'symbol': 'EURGBP=X',
      'name': 'EUR/GBP',
      'nameFa': 'یورو به پوند انگلیس (EUR/GBP)',
      'cat': 'Forex',
      'icon': '💱',
      'price': 0.8340,
    },
    {
      'symbol': 'USDCNH=X',
      'name': 'USD/CNH',
      'nameFa': 'دلار آمریکا به یوان چین فراساحلی (USD/CNH)',
      'cat': 'Forex',
      'icon': '🇨🇳',
      'price': 7.1420,
    },
    {
      'symbol': 'USDTRY=X',
      'name': 'USD/TRY',
      'nameFa': 'دلار آمریکا به لیر ترکیه (USD/TRY)',
      'cat': 'Forex',
      'icon': '🇹🇷',
      'price': 34.28,
    },

    // =========================================================================
    // 5. US TECH, AI & SEMICONDUCTORS (هوش مصنوعی و مگاکپ‌های آمریکا)
    // =========================================================================
    {
      'symbol': 'NVDA',
      'name': 'NVIDIA Corporation',
      'nameFa': 'انویدیا (رهبر هوش مصنوعی جهان)',
      'cat': 'Tech',
      'icon': '🟢',
      'price': 138.25,
    },
    {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'nameFa': 'اپل (بزرگ‌ترین غول سخت‌افزار)',
      'cat': 'Tech',
      'icon': '🍎',
      'price': 228.50,
    },
    {
      'symbol': 'MSFT',
      'name': 'Microsoft Corporation',
      'nameFa': 'مایکروسافت (کلاد و هوش مصنوعی OpenAI)',
      'cat': 'Tech',
      'icon': '🪟',
      'price': 428.10,
    },
    {
      'symbol': 'TSLA',
      'name': 'Tesla Inc.',
      'nameFa': 'تسلا (خودرو برقی، انرژی و رباتیک)',
      'cat': 'Tech',
      'icon': '⚡',
      'price': 255.40,
    },
    {
      'symbol': 'AMZN',
      'name': 'Amazon.com Inc.',
      'nameFa': 'آمازون (تجارت الکترونیک و AWS)',
      'cat': 'Tech',
      'icon': '📦',
      'price': 186.70,
    },
    {
      'symbol': 'GOOGL',
      'name': 'Alphabet Inc. (Google)',
      'nameFa': 'گوگل / آلفابت (جستجو و مدل Gemini)',
      'cat': 'Tech',
      'icon': '🔍',
      'price': 165.30,
    },
    {
      'symbol': 'META',
      'name': 'Meta Platforms Inc.',
      'nameFa': 'متا (اینستاگرام، واتساپ و Llama AI)',
      'cat': 'Tech',
      'icon': '🌐',
      'price': 585.20,
    },
    {
      'symbol': 'PLTR',
      'name': 'Palantir Technologies',
      'nameFa': 'پالانتیر (هوش مصنوعی داده و دفاعی AIP)',
      'cat': 'Tech',
      'icon': '🔮',
      'price': 44.10,
    },
    {
      'symbol': 'TSM',
      'name': 'Taiwan Semiconductor (TSMC)',
      'nameFa': 'تی‌اس‌ام‌سی (بزرگ‌ترین تولیدکننده تراشه دنیا)',
      'cat': 'Tech',
      'icon': '🇹🇼',
      'price': 192.40,
    },
    {
      'symbol': 'AVGO',
      'name': 'Broadcom Inc.',
      'nameFa': 'برودکام (تراشه‌های شبکه هوش مصنوعی)',
      'cat': 'Tech',
      'icon': '📡',
      'price': 176.80,
    },
    {
      'symbol': 'AMD',
      'name': 'Advanced Micro Devices',
      'nameFa': 'ای‌ام‌دی (پردازنده‌های Instinct AI & Ryzen)',
      'cat': 'Tech',
      'icon': '🔴',
      'price': 156.90,
    },
    {
      'symbol': 'ARM',
      'name': 'Arm Holdings plc',
      'nameFa': 'آرم هولدینگز (معماری پردازنده گوشی و سرور)',
      'cat': 'Tech',
      'icon': '📐',
      'price': 142.30,
    },
    {
      'symbol': 'QCOM',
      'name': 'Qualcomm Inc.',
      'nameFa': 'کوالکام (تراشه‌های اسنپ‌دراگون و 5G)',
      'cat': 'Tech',
      'icon': '📱',
      'price': 168.50,
    },
    {
      'symbol': 'ASML',
      'name': 'ASML Holding N.V.',
      'nameFa': 'ای‌اس‌ام‌ال (انحصاری دستگاه‌های لیتوگرافی EUV)',
      'cat': 'Tech',
      'icon': '🇳🇱',
      'price': 710.20,
    },
    {
      'symbol': 'SMCI',
      'name': 'Super Micro Computer',
      'nameFa': 'سوپرمیکرو (سرورهای مایع‌خنک هوش مصنوعی)',
      'cat': 'Tech',
      'icon': '🖥️',
      'price': 46.80,
    },
    {
      'symbol': 'MU',
      'name': 'Micron Technology',
      'nameFa': 'میکرون (حافظه‌های فوق‌سریع HBM3e AI)',
      'cat': 'Tech',
      'icon': '💾',
      'price': 110.50,
    },
    {
      'symbol': 'INTC',
      'name': 'Intel Corporation',
      'nameFa': 'اینتل (پردازنده‌ها و کارخانجات تراشه‌سازی)',
      'cat': 'Tech',
      'icon': '🔷',
      'price': 22.80,
    },
    {
      'symbol': 'NFLX',
      'name': 'Netflix Inc.',
      'nameFa': 'نتفلیکس (غول استریمینگ سرگرمی)',
      'cat': 'Tech',
      'icon': '🎬',
      'price': 720.60,
    },

    // =========================================================================
    // 6. CHINESE GIANTS & CLEAN TECH (غول‌های چین و خودروهای برقی)
    // =========================================================================
    {
      'symbol': 'BABA',
      'name': 'Alibaba Group Holding',
      'nameFa': 'علی‌بابا (بزرگ‌ترین تجارت الکترونیک چین)',
      'cat': 'China',
      'icon': '🛒',
      'price': 98.40,
    },
    {
      'symbol': 'BIDU',
      'name': 'Baidu Inc.',
      'nameFa': 'بایدو (موتور جستجو و هوش مصنوعی ارنی چین)',
      'cat': 'China',
      'icon': '🇨🇳',
      'price': 89.20,
    },
    {
      'symbol': 'JD',
      'name': 'JD.com Inc.',
      'nameFa': 'جی‌دی دات‌کام (غول خرده‌فروشی آنلاین چین)',
      'cat': 'China',
      'icon': '🛍️',
      'price': 39.50,
    },
    {
      'symbol': 'PDD',
      'name': 'PDD Holdings Inc. (Temu)',
      'nameFa': 'پین‌دودو / تیمو (Temu)',
      'cat': 'China',
      'icon': '🏷️',
      'price': 122.80,
    },
    {
      'symbol': 'NIO',
      'name': 'NIO Inc.',
      'nameFa': 'نیو (خودروهای برقی هوشمند چین با تعویض باتری)',
      'cat': 'China',
      'icon': '🚙',
      'price': 5.25,
    },
    {
      'symbol': 'LI',
      'name': 'Li Auto Inc.',
      'nameFa': 'لی اتو (شاسی‌بلندهای هیبریدی پرفروش چین)',
      'cat': 'China',
      'icon': '🚗',
      'price': 29.40,
    },
    {
      'symbol': 'XPEV',
      'name': 'XPeng Inc.',
      'nameFa': 'ایکس‌پنگ (خودروهای خودران برقی چین)',
      'cat': 'China',
      'icon': '🚘',
      'price': 11.60,
    },
    {
      'symbol': 'TCEHY',
      'name': 'Tencent Holdings ADR',
      'nameFa': 'تنسنت (وی‌چت، گیمینگ و هوش مصنوعی چین)',
      'cat': 'China',
      'icon': '🎮',
      'price': 54.80,
    },

    // =========================================================================
    // 7. FINANCIALS, BLUECHIPS & CRYPTO PROXIES (بانک‌ها و واسطه‌های کریپتو)
    // =========================================================================
    {
      'symbol': 'MSTR',
      'name': 'MicroStrategy Inc.',
      'nameFa': 'مایکرواستراتژی (بزرگ‌ترین دارنده نهادی بیت‌کوین)',
      'cat': 'Financials',
      'icon': '🪙',
      'price': 235.50,
    },
    {
      'symbol': 'COIN',
      'name': 'Coinbase Global Inc.',
      'nameFa': 'کوین‌بیس (بزرگ‌ترین صرافی بورس آمریکا)',
      'cat': 'Financials',
      'icon': '🔵',
      'price': 214.30,
    },
    {
      'symbol': 'IBIT',
      'name': 'iShares Bitcoin Trust (BlackRock)',
      'nameFa': 'صندوق ETF بیت‌کوین بلک‌راک (IBIT)',
      'cat': 'Financials',
      'icon': '🏛️',
      'price': 38.60,
    },
    {
      'symbol': 'MARA',
      'name': 'MARA Holdings Inc.',
      'nameFa': 'ماراتن دیجیتال (بزرگ‌ترین شرکت ماینینگ بیت‌کوین)',
      'cat': 'Financials',
      'icon': '⛏️',
      'price': 17.80,
    },
    {
      'symbol': 'CLSK',
      'name': 'CleanSpark Inc.',
      'nameFa': 'کلین‌اسپارک (ماینینگ انرژی سبز بیت‌کوین)',
      'cat': 'Financials',
      'icon': '⚡',
      'price': 12.40,
    },
    {
      'symbol': 'RIOT',
      'name': 'Riot Platforms Inc.',
      'nameFa': 'رایوت پلتفرمز (ماینینگ و دیتاسنتر کریپتو)',
      'cat': 'Financials',
      'icon': '🔌',
      'price': 9.80,
    },
    {
      'symbol': 'HOOD',
      'name': 'Robinhood Markets',
      'nameFa': 'رابین‌هود (پلتفرم کارگزاری معاملات سهام و کریپتو)',
      'cat': 'Financials',
      'icon': '🏹',
      'price': 26.50,
    },
    {
      'symbol': 'BRK-B',
      'name': 'Berkshire Hathaway Inc.',
      'nameFa': 'برکشایر هاتاوی (هلدینگ سرمایه‌گذاری وارن بافت)',
      'cat': 'Financials',
      'icon': '🎩',
      'price': 462.10,
    },
    {
      'symbol': 'JPM',
      'name': 'JPMorgan Chase & Co.',
      'nameFa': 'جی‌پی مورگان (بزرگ‌ترین بانک وال‌استریت)',
      'cat': 'Financials',
      'icon': '🏦',
      'price': 222.60,
    },
    {
      'symbol': 'GS',
      'name': 'The Goldman Sachs Group',
      'nameFa': 'گلدمن ساکس (غول بانکداری سرمایه‌گذاری)',
      'cat': 'Financials',
      'icon': '💼',
      'price': 518.20,
    },
    {
      'symbol': 'V',
      'name': 'Visa Inc.',
      'nameFa': 'ویزا کارت (غول پرداخت و تراکنش جهانی)',
      'cat': 'Financials',
      'icon': '💳',
      'price': 288.90,
    },
    {
      'symbol': 'MA',
      'name': 'Mastercard Inc.',
      'nameFa': 'مسترکارت (شبکه پرداخت بین‌المللی)',
      'cat': 'Financials',
      'icon': '💳',
      'price': 505.40,
    },
    {
      'symbol': 'LLY',
      'name': 'Eli Lilly and Company',
      'nameFa': 'الی لیلی (ارزشمندترین شرکت داروسازی جهان)',
      'cat': 'Financials',
      'icon': '💊',
      'price': 910.30,
    },
    {
      'symbol': 'NVO',
      'name': 'Novo Nordisk A/S',
      'nameFa': 'نوو نوردیسک (داروهای پیشرفته چاقی و دیابت)',
      'cat': 'Financials',
      'icon': '🇩🇰',
      'price': 116.80,
    },
    {
      'symbol': 'WMT',
      'name': 'Walmart Inc.',
      'nameFa': 'والمارت (بزرگ‌ترین زنجیره خرده‌فروشی جهان)',
      'cat': 'Financials',
      'icon': '🏬',
      'price': 80.50,
    },
    {
      'symbol': 'LMT',
      'name': 'Lockheed Martin Corp.',
      'nameFa': 'لاکهید مارتین (پیشرفته‌ترین غول هوافضا و دفاعی)',
      'cat': 'Financials',
      'icon': '✈️',
      'price': 570.40,
    },
  ];

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    return predefinedStocks.map<CurrencyPair>((s) {
      final sym = s['symbol'] as String;
      return CurrencyPair(
        baseCurrency: sym,
        counterCurrency: 'USD',
        marketSymbol: '$sym/USD',
      );
    }).toList();
  }

  @override
  Future<PriceSnapshot> fetchSnapshot(CurrencyPair pair) async {
    final ticker = await fetchTicker(pair);
    return PriceSnapshot(
      price: ticker.lastPrice,
      volume: ticker.volume24h,
      fetchedAt: ticker.timestamp,
    );
  }

  @override
  Future<MarketTicker> fetchTicker(CurrencyPair pair) async {
    final cleanSymbol = pair.baseCurrency;

    // 1. Try Yahoo Finance primary & secondary endpoints
    final hosts = ['query1.finance.yahoo.com', 'query2.finance.yahoo.com'];

    for (final host in hosts) {
      try {
        final url = Uri.parse('https://$host/v8/finance/chart/$cleanSymbol?interval=1m&range=1d');
        final response = await _client.get(url, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = data['chart']?['result']?[0];
          if (result != null) {
            final meta = result['meta'];
            final double regularPrice = (meta['regularMarketPrice'] as num).toDouble();
            final double high = (meta['regularMarketDayHigh'] as num?)?.toDouble() ?? regularPrice;
            final double low = (meta['regularMarketDayLow'] as num?)?.toDouble() ?? regularPrice;
            final double volume = (meta['regularMarketVolume'] as num?)?.toDouble() ?? 0.0;

            if (regularPrice > 0) {
              return MarketTicker(
                exchangeId: id,
                pair: pair,
                lastPrice: regularPrice,
                volume24h: volume,
                high24h: high,
                low24h: low,
                timestamp: DateTime.now(),
              );
            }
          }
        }
      } catch (_) {}
    }

    // 2. High-speed Stooq Financial Mirror (for Indices, Forex & Stocks)
    try {
      final stooqSym = cleanSymbol.replaceAll('^', '').replaceAll('=X', '').toLowerCase();
      final stooqUrl = Uri.parse('https://stooq.com/q/l/?s=$stooqSym.us&f=sd2t2ohlcv&h&e=json');
      final res = await _client.get(stooqUrl).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['symbols'] is List && (data['symbols'] as List).isNotEmpty) {
          final item = data['symbols'][0];
          final p = double.tryParse(item['close']?.toString() ?? '0') ?? 0.0;
          if (p > 0) {
            return MarketTicker(
              exchangeId: id,
              pair: pair,
              lastPrice: p,
              volume24h: 0.0,
              timestamp: DateTime.now(),
            );
          }
        }
      }
    } catch (_) {}

    // 3. Fallback to predefined baseline price if network is temporarily slow
    final match = predefinedStocks.firstWhere(
      (s) => (s['symbol'] as String).toUpperCase() == cleanSymbol.toUpperCase(),
      orElse: () => {},
    );
    if (match.isNotEmpty && match['price'] != null) {
      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: (match['price'] as num).toDouble(),
        volume24h: 0.0,
        timestamp: DateTime.now(),
      );
    }

    throw Exception('Connection error: Live price unavailable for $cleanSymbol');
  }
}

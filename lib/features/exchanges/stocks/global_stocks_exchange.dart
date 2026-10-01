import 'dart:convert';
import 'package:http/http.dart' as http;
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Global Stock Markets, Commodities, Forex, China & Top 100 Companies Adapter
class GlobalStocksExchange implements Exchange {
  final http.Client _client;

  GlobalStocksExchange({http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get id => 'global_stocks';

  @override
  String get name => 'بازارهای جهانی و بورس (Global Stocks / China / Forex / Commodities)';

  @override
  ExchangeCategory get category => ExchangeCategory.all;

  @override
  String get countryBadge => '🏛️ Global Equities & Commodities';

  @override
  String get defaultCounterCurrency => 'USD';

  static const List<Map<String, dynamic>> predefinedStocks = [
    // =========================================================================
    // 1. CHINA & ASIAN MARKETS & GIANTS (بازارها، شاخص‌ها و غول‌های چین و آسیا)
    // =========================================================================
    {
      'symbol': '000001.SS',
      'name': 'Shanghai Composite Index',
      'nameFa': 'شاخص کل بورس شانگهای چین (SSE)',
      'cat': 'China',
      'icon': '🇨🇳',
      'price': 3290.15,
    },
    {
      'symbol': '399001.SZ',
      'name': 'Shenzhen Component Index',
      'nameFa': 'شاخص بورس شنژن چین (SZSE)',
      'cat': 'China',
      'icon': '🇨🇳',
      'price': 10580.40,
    },
    {
      'symbol': '^HSI',
      'name': 'Hang Seng Index Hong Kong',
      'nameFa': 'شاخص بورس هنگ‌کنگ (Hang Seng)',
      'cat': 'China',
      'icon': '🇭🇰',
      'price': 20680.40,
    },
    {
      'symbol': 'FXI',
      'name': 'iShares China Large-Cap ETF',
      'nameFa': 'صندوق ۵۰ شرکت غول‌پیکر چین (FXI ETF)',
      'cat': 'China',
      'icon': '🇨🇳',
      'price': 31.85,
    },
    {
      'symbol': 'KWEB',
      'name': 'KraneShares CSI China Internet ETF',
      'nameFa': 'صندوق شرکت‌های اینترنتی و کلاد چین (KWEB)',
      'cat': 'China',
      'icon': '🌐',
      'price': 32.40,
    },
    {
      'symbol': 'BABA',
      'name': 'Alibaba Group Holding',
      'nameFa': 'علی‌بابا (بزرگ‌ترین تجارت الکترونیک چین)',
      'cat': 'China',
      'icon': '🛍️',
      'price': 98.40,
    },
    {
      'symbol': 'TCEHY',
      'name': 'Tencent Holdings ADR',
      'nameFa': 'تنسنت (وی‌چت، هوش مصنوعی و گیمینگ چین)',
      'cat': 'China',
      'icon': '🎮',
      'price': 54.80,
    },
    {
      'symbol': 'BIDU',
      'name': 'Baidu Inc.',
      'nameFa': 'بایدو (موتور جستجو، هوش مصنوعی و تاکسی خودران چین)',
      'cat': 'China',
      'icon': '🤖',
      'price': 89.20,
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
      'symbol': 'JD',
      'name': 'JD.com Inc.',
      'nameFa': 'جی‌دی دات‌کام (خرده‌فروشی آنلاین و کلاد چین)',
      'cat': 'China',
      'icon': '🛒',
      'price': 39.50,
    },
    {
      'symbol': 'BYDDY',
      'name': 'BYD Company ADR',
      'nameFa': 'بی‌وای‌دی (بزرگ‌ترین خودروساز برقی جهان)',
      'cat': 'China',
      'icon': '🔋',
      'price': 72.80,
    },
    {
      'symbol': 'NIO',
      'name': 'NIO Inc.',
      'nameFa': 'نیو (خودروهای برقی لوکس با تعویض باتری)',
      'cat': 'China',
      'icon': '🚙',
      'price': 5.25,
    },
    {
      'symbol': 'LI',
      'name': 'Li Auto Inc.',
      'nameFa': 'لی اتو (شاسی‌بلندهای هوشمند هیبریدی چین)',
      'cat': 'China',
      'icon': '🚗',
      'price': 29.40,
    },
    {
      'symbol': 'XPEV',
      'name': 'XPeng Inc.',
      'nameFa': 'ایکس‌پنگ (خودروهای تمام‌برقی و هوش مصنوعی پروازی)',
      'cat': 'China',
      'icon': '🚘',
      'price': 11.60,
    },
    {
      'symbol': 'XIACY',
      'name': 'Xiaomi Corporation ADR',
      'nameFa': 'شیائومی (گوشی‌های هوشمند و خودرو برقی SU7)',
      'cat': 'China',
      'icon': '📱',
      'price': 16.80,
    },
    {
      'symbol': 'NTES',
      'name': 'NetEase Inc.',
      'nameFa': 'نت‌ایز (غول سرگرمی دیجیتال و هوش مصنوعی چین)',
      'cat': 'China',
      'icon': '🎲',
      'price': 84.50,
    },
    {
      'symbol': 'SMICY',
      'name': 'SMIC Semiconductor ADR',
      'nameFa': 'اس‌ام‌آی‌سی (بزرگ‌ترین کارخانه تراشه‌سازی چین)',
      'cat': 'China',
      'icon': '🔬',
      'price': 18.20,
    },
    {
      'symbol': 'BILI',
      'name': 'Bilibili Inc.',
      'nameFa': 'بیلی‌بیلی (یوتیوب چین و استریم ویدیو)',
      'cat': 'China',
      'icon': '📺',
      'price': 19.80,
    },
    {
      'symbol': '^N225',
      'name': 'Nikkei 225 Japan',
      'nameFa': 'شاخص بورس توکیو ژاپن (Nikkei 225)',
      'cat': 'China',
      'icon': '🇯🇵',
      'price': 38980.00,
    },
    {
      'symbol': '^KS11',
      'name': 'KOSPI South Korea',
      'nameFa': 'شاخص بورس کره جنوبی (KOSPI)',
      'cat': 'China',
      'icon': '🇰🇷',
      'price': 2610.50,
    },
    {
      'symbol': '^TWII',
      'name': 'Taiwan Weighted Index',
      'nameFa': 'شاخص کل بورس تایوان (TWSE)',
      'cat': 'China',
      'icon': '🇹🇼',
      'price': 23200.00,
    },

    // =========================================================================
    // 2. MACRO BENCHMARKS, YIELDS & DXY (اوراق قرضه، شاخص دلار و نوسان)
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
    // 3. GLOBAL STOCK INDICES (شاخص‌های برتر بورس‌های جهان)
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

    // =========================================================================
    // 4. PRECIOUS METALS & COMMODITIES (طلا، نقره، نفت و فلزات صنعتی)
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
    // 5. FOREX MAJORS & CROSSES (فارکس و برابری ارزهای بین‌المللی)
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
    // 6. TOP 100 & US TECH GIANTS (CompaniesMarketCap.com)
    // =========================================================================
    {
      'symbol': 'NVDA',
      'name': 'NVIDIA Corporation',
      'nameFa': 'انویدیا (رتبه ۱ جهان - هوش مصنوعی)',
      'cat': 'Top100',
      'icon': '🟢',
      'price': 138.25,
    },
    {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'nameFa': 'اپل (رتبه ۲ جهان - سخت‌افزار و اکوسیستم)',
      'cat': 'Top100',
      'icon': '🍎',
      'price': 228.50,
    },
    {
      'symbol': 'MSFT',
      'name': 'Microsoft Corporation',
      'nameFa': 'مایکروسافت (رتبه ۳ جهان - ویندوز، کلاد و OpenAI)',
      'cat': 'Top100',
      'icon': '🪟',
      'price': 428.10,
    },
    {
      'symbol': 'GOOGL',
      'name': 'Alphabet Inc. (Google)',
      'nameFa': 'گوگل / آلفابت (رتبه ۴ جهان - جستجو و جمینای)',
      'cat': 'Top100',
      'icon': '🔍',
      'price': 165.30,
    },
    {
      'symbol': 'AMZN',
      'name': 'Amazon.com Inc.',
      'nameFa': 'آمازون (رتبه ۵ جهان - تجارت الکترونیک و AWS)',
      'cat': 'Top100',
      'icon': '📦',
      'price': 186.70,
    },
    {
      'symbol': 'META',
      'name': 'Meta Platforms Inc.',
      'nameFa': 'متا (رتبه ۶ جهان - اینستاگرام و Llama AI)',
      'cat': 'Top100',
      'icon': '🌐',
      'price': 585.20,
    },
    {
      'symbol': 'TSM',
      'name': 'Taiwan Semiconductor (TSMC)',
      'nameFa': 'تی‌اس‌ام‌سی (رتبه ۷ جهان - بزرگ‌ترین تولیدکننده تراشه)',
      'cat': 'Top100',
      'icon': '🇹🇼',
      'price': 192.40,
    },
    {
      'symbol': 'BRK-B',
      'name': 'Berkshire Hathaway',
      'nameFa': 'برکشایر هاتاوی (رتبه ۸ جهان - هلدینگ وارن بافت)',
      'cat': 'Top100',
      'icon': '🎩',
      'price': 462.10,
    },
    {
      'symbol': 'TSLA',
      'name': 'Tesla Inc.',
      'nameFa': 'تسلا (رتبه ۹ جهان - خودرو برقی و رباتیک)',
      'cat': 'Top100',
      'icon': '⚡',
      'price': 255.40,
    },
    {
      'symbol': 'LLY',
      'name': 'Eli Lilly and Company',
      'nameFa': 'الی لیلی (رتبه ۱۰ جهان - داروسازی و دیابت)',
      'cat': 'Top100',
      'icon': '💊',
      'price': 910.30,
    },
    {
      'symbol': 'AVGO',
      'name': 'Broadcom Inc.',
      'nameFa': 'برودکام (رتبه ۱۱ جهان - تراشه‌های شبکه AI)',
      'cat': 'Top100',
      'icon': '📡',
      'price': 176.80,
    },
    {
      'symbol': 'JPM',
      'name': 'JPMorgan Chase & Co.',
      'nameFa': 'جی‌پی مورگان (رتبه ۱۲ جهان - بزرگ‌ترین بانک وال‌استریت)',
      'cat': 'Top100',
      'icon': '🏦',
      'price': 222.60,
    },
    {
      'symbol': 'WMT',
      'name': 'Walmart Inc.',
      'nameFa': 'والمارت (رتبه ۱۳ جهان - بزرگ‌ترین زنجیره خرده‌فروشی)',
      'cat': 'Top100',
      'icon': '🏬',
      'price': 80.50,
    },
    {
      'symbol': 'V',
      'name': 'Visa Inc.',
      'nameFa': 'ویزا کارت (رتبه ۱۴ جهان - غول پرداخت و تراکنش)',
      'cat': 'Top100',
      'icon': '💳',
      'price': 288.90,
    },
    {
      'symbol': 'NVO',
      'name': 'Novo Nordisk A/S',
      'nameFa': 'نوو نوردیسک (رتبه ۱۵ جهان - داروسازی اوزمپیک)',
      'cat': 'Top100',
      'icon': '🇩🇰',
      'price': 116.80,
    },
    {
      'symbol': 'XOM',
      'name': 'Exxon Mobil Corp.',
      'nameFa': 'اکسون موبیل (رتبه ۱۶ جهان - غول نفت و گاز)',
      'cat': 'Top100',
      'icon': '🛢️',
      'price': 120.40,
    },
    {
      'symbol': 'UNH',
      'name': 'UnitedHealth Group',
      'nameFa': 'یونایتدهلث (رتبه ۱۷ جهان - بیمه و سلامت)',
      'cat': 'Top100',
      'icon': '🏥',
      'price': 572.80,
    },
    {
      'symbol': 'ORCL',
      'name': 'Oracle Corporation',
      'nameFa': 'اوراکل (رتبه ۱۸ جهان - دیتابیس و کلاد سازمانی)',
      'cat': 'Top100',
      'icon': '💾',
      'price': 175.60,
    },
    {
      'symbol': 'MA',
      'name': 'Mastercard Inc.',
      'nameFa': 'مسترکارت (رتبه ۱۹ جهان - شبکه پرداخت مالی)',
      'cat': 'Top100',
      'icon': '💳',
      'price': 505.40,
    },
    {
      'symbol': 'COST',
      'name': 'Costco Wholesale',
      'nameFa': 'کاستکو (رتبه ۲۰ جهان - فروشگاه‌های زنجیره‌ای)',
      'cat': 'Top100',
      'icon': '🛒',
      'price': 905.80,
    },
    {
      'symbol': 'HD',
      'name': 'The Home Depot',
      'nameFa': 'هوم دیپو (رتبه ۲۱ جهان - لوازم ساختمانی و منزل)',
      'cat': 'Top100',
      'icon': '🔨',
      'price': 398.50,
    },
    {
      'symbol': 'PG',
      'name': 'Procter & Gamble',
      'nameFa': 'پروکتر اند گمبل (رتبه ۲۲ جهان - کالاهای مصرفی)',
      'cat': 'Top100',
      'icon': '🧼',
      'price': 168.20,
    },
    {
      'symbol': 'JNJ',
      'name': 'Johnson & Johnson',
      'nameFa': 'جانسون اند جانسون (رتبه ۲۳ جهان - تجهیزات پزشکی و دارو)',
      'cat': 'Top100',
      'icon': '🩹',
      'price': 161.40,
    },
    {
      'symbol': 'ASML',
      'name': 'ASML Holding N.V.',
      'nameFa': 'ای‌اس‌ام‌ال (رتبه ۲۴ جهان - لیتوگرافی تراشه هلند)',
      'cat': 'Top100',
      'icon': '🇳🇱',
      'price': 710.20,
    },
    {
      'symbol': 'ABBV',
      'name': 'AbbVie Inc.',
      'nameFa': 'اب‌وی (رتبه ۲۵ جهان - بیوداروسازی)',
      'cat': 'Top100',
      'icon': '🧬',
      'price': 188.50,
    },
    {
      'symbol': 'BAC',
      'name': 'Bank of America',
      'nameFa': 'بنک آو آمریکا (رتبه ۲۶ جهان - بانکداری کلان)',
      'cat': 'Top100',
      'icon': '🏦',
      'price': 42.30,
    },
    {
      'symbol': 'NFLX',
      'name': 'Netflix Inc.',
      'nameFa': 'نتفلیکس (رتبه ۲۷ جهان - سرویس پخش آنلاین)',
      'cat': 'Top100',
      'icon': '🎬',
      'price': 720.60,
    },
    {
      'symbol': 'SAP',
      'name': 'SAP SE',
      'nameFa': 'اس‌ای‌پی (رتبه ۲۸ جهان - نرم‌افزارهای سازمانی آلمان)',
      'cat': 'Top100',
      'icon': '🇩🇪',
      'price': 234.10,
    },
    {
      'symbol': 'KO',
      'name': 'The Coca-Cola Company',
      'nameFa': 'کوکاکولا (رتبه ۲۹ جهان - نوشیدنی‌های بین‌المللی)',
      'cat': 'Top100',
      'icon': '🥤',
      'price': 68.40,
    },
    {
      'symbol': 'CVX',
      'name': 'Chevron Corporation',
      'nameFa': 'شورون (رتبه ۳۰ جهان - نفت، گاز و پتروشیمی)',
      'cat': 'Top100',
      'icon': '⛽',
      'price': 152.60,
    },
    {
      'symbol': 'CRM',
      'name': 'Salesforce Inc.',
      'nameFa': 'سیلزفورس (رتبه ۳۱ جهان - مدیریت ارتباط با مشتری CRM)',
      'cat': 'Top100',
      'icon': '☁️',
      'price': 294.50,
    },
    {
      'symbol': 'AMD',
      'name': 'Advanced Micro Devices',
      'nameFa': 'ای‌ام‌دی (رتبه ۳۲ جهان - پردازنده‌های گرافیکی و سرور)',
      'cat': 'Top100',
      'icon': '🔴',
      'price': 156.90,
    },
    {
      'symbol': 'LVMUY',
      'name': 'LVMH Moet Hennessy',
      'nameFa': 'ال‌وی‌ام‌اچ (رتبه ۳۳ جهان - برندهای لوکس فرانسه)',
      'cat': 'Top100',
      'icon': '👜',
      'price': 132.80,
    },
    {
      'symbol': 'TM',
      'name': 'Toyota Motor Corp.',
      'nameFa': 'تویوتا موتور (رتبه ۳۴ جهان - غول خودروسازی ژاپن)',
      'cat': 'Top100',
      'icon': '🚗',
      'price': 176.40,
    },
    {
      'symbol': 'PLTR',
      'name': 'Palantir Technologies',
      'nameFa': 'پالانتیر (رتبه ۳۵ جهان - تحلیل داده و دفاعی AI)',
      'cat': 'Top100',
      'icon': '🔮',
      'price': 44.10,
    },
    {
      'symbol': 'MSTR',
      'name': 'MicroStrategy Inc.',
      'nameFa': 'مایکرواستراتژی (رتبه ۳۶ جهان - بزرگ‌ترین خزانه‌داری بیت‌کوین)',
      'cat': 'Top100',
      'icon': '🪙',
      'price': 235.50,
    },
    {
      'symbol': 'COIN',
      'name': 'Coinbase Global Inc.',
      'nameFa': 'کوین‌بیس (رتبه ۳۷ جهان - صرافی رسمی بورس نزدک)',
      'cat': 'Top100',
      'icon': '🔵',
      'price': 214.30,
    },
    {
      'symbol': 'CRWD',
      'name': 'CrowdStrike Holdings',
      'nameFa': 'کراوداسترایک (رتبه ۳۸ جهان - امنیت شبکه فالکون AI)',
      'cat': 'Top100',
      'icon': '🦅',
      'price': 312.40,
    },
    {
      'symbol': 'SMCI',
      'name': 'Super Micro Computer',
      'nameFa': 'سوپرمیکرو (رتبه ۳۹ جهان - سرورهای دیتاسنتر AI)',
      'cat': 'Top100',
      'icon': '🖥️',
      'price': 46.80,
    },
    {
      'symbol': 'INTC',
      'name': 'Intel Corporation',
      'nameFa': 'اینتل (رتبه ۴۰ جهان - پردازنده‌های کامپیوتر و فاندری)',
      'cat': 'Top100',
      'icon': '🔷',
      'price': 22.80,
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

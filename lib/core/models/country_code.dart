class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  static const CountryCode defaultCountry = CountryCode(
    name: 'India',
    code: 'IN',
    dialCode: '+91',
    flag: '🇮🇳',
  );

  static const List<CountryCode> allCountries = [
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryCode(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    CountryCode(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
    CountryCode(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
    CountryCode(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
    CountryCode(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
  ];
}

/// Attribution for bundled photos (required by their CC BY-SA licences).
/// Mirrors `assets/CREDITS.md`.
class PhotoCredit {
  const PhotoCredit({
    required this.asset,
    required this.subjectEn,
    required this.subjectAr,
    required this.author,
    required this.license,
    required this.sourceUrl,
  });

  final String asset;
  final String subjectEn;
  final String subjectAr;
  final String author;
  final String license;
  final String sourceUrl;
}

abstract final class BundledPhotos {
  static const onboarding = [
    PhotoCredit(
      asset: 'assets/images/onboarding_1.jpg',
      subjectEn: 'Three domes of Oia, Santorini',
      subjectAr: 'قباب أويا الثلاث، سانتوريني',
      author: 'Giles Laurent',
      license: 'CC BY-SA 4.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:1000_Three_domes_of_Oia_in_Santorini_Photo_by_Giles_Laurent.jpg',
    ),
    PhotoCredit(
      asset: 'assets/images/onboarding_2.jpg',
      subjectEn: 'Yasaka-dori and the Tower of Yasaka, Kyoto',
      subjectAr: 'شارع ياساكا وبرج ياساكا، كيوتو',
      author: 'Basile Morin',
      license: 'CC BY-SA 4.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Yasaka-dori_early_morning_with_street_lanterns_and_the_Tower_of_Yasaka_(Hokan-ji_Temple),_Kyoto,_Japan.jpg',
    ),
    PhotoCredit(
      asset: 'assets/images/onboarding_3.jpg',
      subjectEn: 'Matterhorn at sunset',
      subjectAr: 'جبل ماترهورن عند الغروب',
      author: 'Sam Ferrara',
      license: 'CC0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Matterhorn_sunset_2016_(Unsplash).jpg',
    ),
  ];
}

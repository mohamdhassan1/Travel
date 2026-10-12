-- =============================================================================
-- Rahala — catalog seed data
--
-- WHAT THIS IS
--   A sample travel catalog for development and demonstration: 4 categories,
--   20 destinations and 40 packages, in English and Arabic (12 + 24 originally,
--   8 + 16 added in Phase 8 to balance the categories).
--
-- HONESTY NOTES
--   * Destination facts, coordinates and seasons are real.
--   * Package prices/durations are ILLUSTRATIVE sample values chosen to be
--     plausible. Rahala is a portfolio app, not a tour operator; there is no
--     inventory/availability model and no payment processing.
--   * There are deliberately NO ratings, reviews or testimonials.
--
-- IMAGES
--   Hotlinked from Wikimedia Commons (Featured / Quality images). Each
--   destination's `image_credit` names the photographers and licences
--   (CC BY / CC BY-SA / FAL / CC0). Every URL was checked to return
--   200 image/jpeg on 2026-10-01. No image files are stored in the repo.
--
-- SAFE TO RE-RUN: categories/destinations/packages are upserted by their
-- natural keys (id, slug, (destination_id, name_en)). No user data is touched.
-- Run AFTER both migrations in supabase/migrations/ (the second one adds the
-- (destination_id, name_en) key used by the package upsert below).
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- Categories
-- -----------------------------------------------------------------------------
insert into public.categories (id, name_en, name_ar, icon, sort_order) values
  ('heritage', 'Heritage', 'تراث وتاريخ', 'heritage', 1),
  ('city',     'Cities',   'مدن',          'city',     2),
  ('beach',    'Beaches',  'شواطئ',        'beach',    3),
  ('islands',  'Islands',  'جزر',          'islands',  4)
on conflict (id) do update set
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  icon = excluded.icon,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Destinations
-- -----------------------------------------------------------------------------
insert into public.destinations (
  slug, category_id, name_en, name_ar, country_en, country_ar,
  summary_en, summary_ar, description_en, description_ar,
  best_season_en, best_season_ar, latitude, longitude,
  cover_image, gallery, image_credit, is_featured
) values
(
  'cairo', 'heritage', 'Cairo', 'القاهرة', 'Egypt', 'مصر',
  'Pyramids, historic mosques and a city that never sleeps on the Nile.',
  'الأهرامات والمساجد التاريخية ومدينة لا تنام على ضفاف النيل.',
  'Egypt''s capital pairs the Giza plateau — home to the Great Pyramid and the Sphinx — with the centuries-old mosques of Islamic Cairo, the Khan el-Khalili bazaar and the Grand Egyptian Museum. Evenings are best spent on a felucca or a rooftop overlooking the Nile.',
  'تجمع عاصمة مصر بين هضبة الجيزة — موطن الهرم الأكبر وأبو الهول — ومساجد القاهرة الإسلامية العريقة وسوق خان الخليلي والمتحف المصري الكبير. وأجمل الأمسيات تكون على متن فلوكة أو من سطح يطل على النيل.',
  'October – April', 'أكتوبر – أبريل', 30.0444, 31.2357,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/All_Gizah_Pyramids.jpg/1280px-All_Gizah_Pyramids.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/db/Great_Sphinx_of_Giza_%28%D8%A3%D8%A8%D9%88_%D8%A7%D9%84%D9%87%D9%88%D9%84%29.jpg/1280px-Great_Sphinx_of_Giza_%28%D8%A3%D8%A8%D9%88_%D8%A7%D9%84%D9%87%D9%88%D9%84%29.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e0/Kairo_Ibn_Tulun_Moschee_BW_5.jpg/1280px-Kairo_Ibn_Tulun_Moschee_BW_5.jpg'
  ],
  'Wikimedia Commons: Ricardo Liberato (CC BY-SA 2.0); Petar Milošević (CC BY-SA 4.0); Berthold Werner (CC BY 3.0)',
  true
),
(
  'luxor', 'heritage', 'Luxor', 'الأقصر', 'Egypt', 'مصر',
  'The world''s greatest open-air museum on the banks of the Nile.',
  'أعظم متحف مفتوح في العالم على ضفاف النيل.',
  'Ancient Thebes holds the vast temple complexes of Karnak and Luxor on the east bank, and the Valley of the Kings, the Temple of Hatshepsut and the Colossi of Memnon on the west. Sunrise hot-air balloon flights show both banks at once.',
  'تضم طيبة القديمة مجمعَي معابد الكرنك والأقصر على الضفة الشرقية، ووادي الملوك ومعبد حتشبسوت وتمثالَي ممنون على الضفة الغربية. وتمنحك رحلات المنطاد عند الشروق إطلالة على الضفتين معًا.',
  'October – April', 'أكتوبر – أبريل', 25.6872, 32.6396,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Templo_de_Karnak%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_144.jpg/1280px-Templo_de_Karnak%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_144.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/74/Templo_funerario_de_Hatshepsut%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_13.jpg/1280px-Templo_funerario_de_Hatshepsut%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_13.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a1/Colosos_de_Memn%C3%B3n%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_132.jpg/1280px-Colosos_de_Memn%C3%B3n%2C_Luxor%2C_Egipto%2C_2022-04-03%2C_DD_132.jpg'
  ],
  'Wikimedia Commons: Diego Delso (CC BY-SA 4.0)',
  true
),
(
  'aswan', 'heritage', 'Aswan', 'أسوان', 'Egypt', 'مصر',
  'Granite islands, Nubian villages and the Temple of Philae.',
  'جزر من الجرانيت وقرى نوبية ومعبد فيلة.',
  'Egypt''s southernmost city sits on the calmest stretch of the Nile, with feluccas drifting between granite islands. Visit the Temple of Philae and the colourful Nubian villages on the west bank, then continue south to the rock temples of Abu Simbel.',
  'أسوان، أقصى مدن مصر جنوبًا، تقع على أهدأ مقاطع النيل حيث تتهادى الفلوكات بين جزر الجرانيت. زر معبد فيلة والقرى النوبية الملونة على الضفة الغربية، ثم واصل جنوبًا إلى معابد أبو سمبل المنحوتة في الصخر.',
  'November – February', 'نوفمبر – فبراير', 24.0889, 32.8998,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8c/File%2C_Asu%C3%A1n%2C_Egipto%2C_2022-04-01%2C_DD_144.jpg/1280px-File%2C_Asu%C3%A1n%2C_Egipto%2C_2022-04-01%2C_DD_144.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/40/File%2C_Asu%C3%A1n%2C_Egipto%2C_2022-04-01%2C_DD_142.jpg/1280px-File%2C_Asu%C3%A1n%2C_Egipto%2C_2022-04-01%2C_DD_142.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7d/A_man_and_his_donkey_on_the_way_back_from_the_field_in_Aswan%2C_Egypt_%28edited%29.jpg/1280px-A_man_and_his_donkey_on_the_way_back_from_the_field_in_Aswan%2C_Egypt_%28edited%29.jpg'
  ],
  'Wikimedia Commons: Diego Delso (CC BY-SA 4.0); Mohamed Hozyen, edited by Aristeas (CC BY-SA 4.0)',
  false
),
(
  'sharm-el-sheikh', 'beach', 'Sharm El Sheikh', 'شرم الشيخ', 'Egypt', 'مصر',
  'World-class diving on the coral reefs of the Red Sea.',
  'غوص عالمي المستوى بين الشعاب المرجانية في البحر الأحمر.',
  'At the southern tip of Sinai, Sharm El Sheikh is the gateway to Ras Mohammed National Park and the Strait of Tiran, where coral walls drop into deep blue water. Snorkellers and divers can meet turtles, reef rays and angelfish close to shore.',
  'تقع شرم الشيخ عند الطرف الجنوبي لسيناء، وهي بوابة محمية رأس محمد ومضيق تيران حيث تنحدر جدران المرجان إلى المياه العميقة. ويمكن لهواة الغطس والغوص رؤية السلاحف وأسماك الراي والأسماك الملائكية قرب الشاطئ.',
  'March – May, September – November', 'مارس – مايو، سبتمبر – نوفمبر', 27.9158, 34.3300,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8b/Tortuga_carey_%28Eretmochelys_imbricata%29%2C_parque_nacional_Ras_Muhammad%2C_Egipto%2C_2022-03-28%2C_DD_56.jpg/1280px-Tortuga_carey_%28Eretmochelys_imbricata%29%2C_parque_nacional_Ras_Muhammad%2C_Egipto%2C_2022-03-28%2C_DD_56.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/12/Raya_de_arrecife_%28Taeniura_lymma%29%2C_Temple%2C_Sharm_el-Sheij%2C_Egipto%2C_2022-03-26%2C_DD_05.jpg/1280px-Raya_de_arrecife_%28Taeniura_lymma%29%2C_Temple%2C_Sharm_el-Sheij%2C_Egipto%2C_2022-03-26%2C_DD_05.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0a/Pez_%C3%A1ngel_real_%28Pygoplites_diacanthus%29%2C_parque_nacional_Ras_Muhammad%2C_Egipto%2C_2022-03-26%2C_DD_155.jpg/1280px-Pez_%C3%A1ngel_real_%28Pygoplites_diacanthus%29%2C_parque_nacional_Ras_Muhammad%2C_Egipto%2C_2022-03-26%2C_DD_155.jpg'
  ],
  'Wikimedia Commons: Diego Delso (CC BY-SA 4.0)',
  true
),
(
  'petra', 'heritage', 'Petra', 'البتراء', 'Jordan', 'الأردن',
  'The rose-red Nabataean city carved into desert cliffs.',
  'مدينة الأنباط الوردية المنحوتة في صخور الصحراء.',
  'Walk through the narrow Siq to reach the Treasury, then climb about 800 rock-cut steps to the Monastery. Petra is a UNESCO World Heritage Site, and the desert camps of Wadi Rum are a short drive away.',
  'امشِ عبر السيق الضيق لتصل إلى الخزنة، ثم اصعد نحو ٨٠٠ درجة منحوتة في الصخر إلى الدير. البتراء موقع مدرج على قائمة اليونسكو للتراث العالمي، ومخيمات وادي رم الصحراوية على مسافة قصيرة بالسيارة.',
  'March – May, September – November', 'مارس – مايو، سبتمبر – نوفمبر', 30.3285, 35.4444,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/The_Monastery%2C_Petra%2C_Jordan8.jpg/1280px-The_Monastery%2C_Petra%2C_Jordan8.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d7/Petra_Jordan_BW_43.JPG/1280px-Petra_Jordan_BW_43.JPG'
  ],
  'Wikimedia Commons: Diego Delso (CC BY-SA 3.0); Berthold Werner (CC BY-SA 3.0)',
  false
),
(
  'istanbul', 'city', 'Istanbul', 'إسطنبول', 'Türkiye', 'تركيا',
  'Two continents, one skyline of domes and minarets.',
  'قارتان وأفق واحد من القباب والمآذن.',
  'Istanbul straddles the Bosphorus between Europe and Asia. Explore Hagia Sophia, the Blue Mosque and Topkapı Palace in the old city, cross to Kadıköy by ferry, and end the day with tea above the Golden Horn.',
  'تمتد إسطنبول على ضفتي البوسفور بين أوروبا وآسيا. استكشف آيا صوفيا والجامع الأزرق وقصر طوب قابي في المدينة القديمة، واعبر بالعبّارة إلى قاضي كوي، واختم يومك بالشاي فوق القرن الذهبي.',
  'April – June, September – October', 'أبريل – يونيو، سبتمبر – أكتوبر', 41.0082, 28.9784,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/22/Hagia_Sophia_Mars_2013.jpg/1280px-Hagia_Sophia_Mars_2013.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8d/Istanbul_asv2020-02_img55_View_of_Be%C5%9Fikta%C5%9F.jpg/1280px-Istanbul_asv2020-02_img55_View_of_Be%C5%9Fikta%C5%9F.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8c/Mezquita_Azul%2C_Estambul%2C_Turqu%C3%ADa%2C_2024-09-30%2C_DD_48-50_HDR.jpg/1280px-Mezquita_Azul%2C_Estambul%2C_Turqu%C3%ADa%2C_2024-09-30%2C_DD_48-50_HDR.jpg'
  ],
  'Wikimedia Commons: Arild Vågen (CC BY-SA 3.0); A.Savin (FAL); Diego Delso (CC BY-SA 4.0)',
  true
),
(
  'dubai', 'city', 'Dubai', 'دبي', 'United Arab Emirates', 'الإمارات العربية المتحدة',
  'Desert, sea and some of the world''s most ambitious architecture.',
  'صحراء وبحر وبعض أكثر المعالم المعمارية طموحًا في العالم.',
  'From the Burj Khalifa and Dubai Marina to the old souks along Dubai Creek, the city mixes futuristic landmarks with traditional abra boat rides. Desert safaris and beach days are both within an hour of the centre.',
  'من برج خليفة ودبي مارينا إلى الأسواق القديمة على خور دبي، تمزج المدينة بين المعالم المستقبلية وجولات العَبرة التقليدية. ورحلات السفاري الصحراوية وأيام الشاطئ كلها على بعد أقل من ساعة من وسط المدينة.',
  'November – March', 'نوفمبر – مارس', 25.2048, 55.2708,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d0/Madinat_Jumeirah-Dubai3303.JPG/1280px-Madinat_Jumeirah-Dubai3303.JPG',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/39/Dubai_creek-2011_%287%29.JPG/1280px-Dubai_creek-2011_%287%29.JPG'
  ],
  'Wikimedia Commons: Diego Delso (CC BY-SA 4.0); Alberto-g-rovi (CC BY-SA 3.0)',
  false
),
(
  'paris', 'city', 'Paris', 'باريس', 'France', 'فرنسا',
  'Boulevards, museums and cafés along the Seine.',
  'جادات ومتاحف ومقاهٍ على ضفاف السين.',
  'See the Eiffel Tower, the Louvre and the Musée d''Orsay, then explore Montmartre and the Marais on foot. Paris rewards slow days: long lunches, evening walks along the Seine and day trips to Versailles.',
  'شاهد برج إيفل ومتحفَي اللوفر وأورسيه، ثم تجوّل سيرًا في مونمارتر والماريه. باريس تكافئ من يتمهّل: غداء طويل ونزهات مسائية على ضفاف السين ورحلات يومية إلى فرساي.',
  'April – June, September – October', 'أبريل – يونيو، سبتمبر – أكتوبر', 48.8566, 2.3522,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/Paris_-_The_Eiffel_Tower_in_spring_-_2307.jpg/1280px-Paris_-_The_Eiffel_Tower_in_spring_-_2307.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2e/Eiffel_Tower_in_2022_02.jpg/1280px-Eiffel_Tower_in_2022_02.jpg'
  ],
  'Wikimedia Commons: Jorge Royan (CC BY-SA 3.0); Maksim Sokolov (CC BY-SA 4.0)',
  true
),
(
  'rome', 'heritage', 'Rome', 'روما', 'Italy', 'إيطاليا',
  'Nearly three thousand years of history in one walkable city.',
  'قرابة ثلاثة آلاف عام من التاريخ في مدينة يمكن استكشافها سيرًا.',
  'Stand inside the Colosseum, walk through the Roman Forum and the Pantheon, and visit St Peter''s Basilica and the Vatican Museums. Between the sights, Rome''s piazzas and trattorias set the pace.',
  'قف داخل الكولوسيوم وتجوّل في المنتدى الروماني والبانثيون، وزر كاتدرائية القديس بطرس ومتاحف الفاتيكان. وبين المعالم، تضبط ساحات روما ومطاعمها الشعبية إيقاع يومك.',
  'April – June, September – October', 'أبريل – يونيو، سبتمبر – أكتوبر', 41.9028, 12.4964,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d8/Colosseum_in_Rome-April_2007-1-_copie_2B.jpg/1280px-Colosseum_in_Rome-April_2007-1-_copie_2B.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c7/Rom_%28IT%29%2C_Kolosseum_--_2024_--_0610.jpg/1280px-Rom_%28IT%29%2C_Kolosseum_--_2024_--_0610.jpg'
  ],
  'Wikimedia Commons: Diliff (CC BY-SA 2.5); Anil Öztas (CC BY 4.0)',
  false
),
(
  'kyoto', 'heritage', 'Kyoto', 'كيوتو', 'Japan', 'اليابان',
  'Temples, gardens and lantern-lit lanes of old Japan.',
  'معابد وحدائق وأزقة مضاءة بالفوانيس من اليابان القديمة.',
  'Japan''s former imperial capital has more than a thousand temples and shrines. Walk the vermilion gates of Fushimi Inari, the bamboo grove of Arashiyama and the preserved streets of Higashiyama — ideally early in the morning.',
  'تضم عاصمة اليابان الإمبراطورية السابقة أكثر من ألف معبد ومزار. امشِ بين البوابات القرمزية في فوشيمي إيناري وغابة الخيزران في أراشيياما وشوارع هيغاشيياما التاريخية، ويفضَّل ذلك في الصباح الباكر.',
  'March – May, October – November', 'مارس – مايو، أكتوبر – نوفمبر', 35.0116, 135.7681,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ed/Yasaka-dori_early_morning_with_street_lanterns_and_the_Tower_of_Yasaka_%28Hokan-ji_Temple%29%2C_Kyoto%2C_Japan.jpg/1280px-Yasaka-dori_early_morning_with_street_lanterns_and_the_Tower_of_Yasaka_%28Hokan-ji_Temple%29%2C_Kyoto%2C_Japan.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4a/Bamboo_Forest%2C_Arashiyama%2C_Kyoto%2C_Japan.jpg/1280px-Bamboo_Forest%2C_Arashiyama%2C_Kyoto%2C_Japan.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/66/Pedestrian_road_with_pavements_and_paper_umbrellas%2C_Higashiyama-ku%2C_Kyoto%2C_Japan%2C_early_morning.jpg/1280px-Pedestrian_road_with_pavements_and_paper_umbrellas%2C_Higashiyama-ku%2C_Kyoto%2C_Japan%2C_early_morning.jpg'
  ],
  'Wikimedia Commons: Basile Morin (CC BY-SA 4.0)',
  true
),
(
  'bali', 'islands', 'Bali', 'بالي', 'Indonesia', 'إندونيسيا',
  'Rice terraces, sea temples and volcanic sunrises.',
  'مدرجات الأرز ومعابد البحر وشروق الشمس فوق البراكين.',
  'Base yourself in Ubud for the rice terraces and traditional dance, then head to the coast for the sea temple of Tanah Lot at sunset. The south of the island has surf beaches, and Mount Batur is a popular sunrise hike.',
  'اتخذ من أوبود مقرًا لزيارة مدرجات الأرز ومشاهدة الرقص التقليدي، ثم توجّه إلى الساحل لمشاهدة معبد تاناه لوت البحري عند الغروب. ويضم جنوب الجزيرة شواطئ لركوب الأمواج، بينما يُعد جبل باتور وجهة شهيرة للمشي عند الشروق.',
  'April – October', 'أبريل – أكتوبر', -8.5069, 115.2625,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8a/Rice_terraces%2C_Bali.jpg/1280px-Rice_terraces%2C_Bali.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f5/Tanah_Lot%2C_Bali%2C_Indonesia%2C_20220827_1008_1159.jpg/1280px-Tanah_Lot%2C_Bali%2C_Indonesia%2C_20220827_1008_1159.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Rice_fields%2C_Bedulu_near_Ubud%2C_Bali%2C_Indonesia%2C_20220824_1039_0665.jpg/1280px-Rice_fields%2C_Bedulu_near_Ubud%2C_Bali%2C_Indonesia%2C_20220824_1039_0665.jpg'
  ],
  'Wikimedia Commons: Vyacheslav Argenberg (CC BY 4.0); Jakub Hałun (CC BY-SA 4.0)',
  false
),
(
  'santorini', 'islands', 'Santorini', 'سانتوريني', 'Greece', 'اليونان',
  'Whitewashed villages on the rim of a volcanic caldera.',
  'قرى بيضاء على حافة فوهة بركانية.',
  'The cliff-top villages of Oia and Fira look over a caldera flooded by the sea. Walk the trail between them, swim at the red and black volcanic beaches, and visit the Bronze Age site of Akrotiri.',
  'تطل قريتا أويا وفيرا المعلّقتان على المنحدرات على فوهة بركانية غمرها البحر. امشِ على الدرب بينهما، واسبح في الشواطئ البركانية الحمراء والسوداء، وزر موقع أكروتيري من العصر البرونزي.',
  'May – June, September – October', 'مايو – يونيو، سبتمبر – أكتوبر', 36.4167, 25.4333,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/1000_Three_domes_of_Oia_in_Santorini_Photo_by_Giles_Laurent.jpg/1280px-1000_Three_domes_of_Oia_in_Santorini_Photo_by_Giles_Laurent.jpg',
  array[
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/48/Thira_%28Santorini%29_-_Ia-01.jpg/1280px-Thira_%28Santorini%29_-_Ia-01.jpg',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/50/%CE%9F%CE%AF%CE%B1_1121.jpg/1280px-%CE%9F%CE%AF%CE%B1_1121.jpg'
  ],
  'Wikimedia Commons: Giles Laurent (CC BY-SA 4.0); Taxiarchos228 (FAL); C messier (CC BY-SA 4.0)',
  true
)
on conflict (slug) do update set
  category_id = excluded.category_id,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  country_en = excluded.country_en,
  country_ar = excluded.country_ar,
  summary_en = excluded.summary_en,
  summary_ar = excluded.summary_ar,
  description_en = excluded.description_en,
  description_ar = excluded.description_ar,
  best_season_en = excluded.best_season_en,
  best_season_ar = excluded.best_season_ar,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  cover_image = excluded.cover_image,
  gallery = excluded.gallery,
  image_credit = excluded.image_credit,
  is_featured = excluded.is_featured;

-- -----------------------------------------------------------------------------
-- Packages (sample prices in USD per person)
-- -----------------------------------------------------------------------------
insert into public.destination_packages (
  destination_id, name_en, name_ar, description_en, description_ar,
  duration_days, price_per_person, currency, max_travelers, includes_en, includes_ar, sort_order
)
select d.id, v.name_en, v.name_ar, v.description_en, v.description_ar,
       v.duration_days, v.price, 'USD', v.max_travelers, v.includes_en, v.includes_ar, v.sort_order
from (values
  ('cairo', 'Pyramids & Old Cairo Discovery', 'اكتشاف الأهرامات والقاهرة القديمة',
   'Four days covering the Giza plateau, the Grand Egyptian Museum and Islamic Cairo with a licensed Egyptologist.',
   'أربعة أيام تشمل هضبة الجيزة والمتحف المصري الكبير والقاهرة الإسلامية برفقة مرشد أثري مرخّص.',
   4, 420.00, 8,
   array['3 nights hotel with breakfast', 'Licensed Egyptologist guide', 'Giza plateau and museum entry', 'Airport transfers'],
   array['٣ ليالٍ في فندق مع الإفطار', 'مرشد أثري مرخّص', 'دخول هضبة الجيزة والمتحف', 'التنقل من وإلى المطار'], 1),
  ('cairo', 'Cairo Weekend Escape', 'عطلة نهاية الأسبوع في القاهرة',
   'A short break for the pyramids and an evening in Khan el-Khalili.',
   'استراحة قصيرة لزيارة الأهرامات وقضاء أمسية في خان الخليلي.',
   2, 180.00, 6,
   array['1 night hotel with breakfast', 'Giza plateau entry', 'Khan el-Khalili walking tour'],
   array['ليلة في فندق مع الإفطار', 'دخول هضبة الجيزة', 'جولة سيرًا في خان الخليلي'], 2),

  ('luxor', 'Luxor East & West Bank', 'الأقصر بضفتيها الشرقية والغربية',
   'Karnak and Luxor temples on day one, the Valley of the Kings and Hatshepsut on day two.',
   'معبدا الكرنك والأقصر في اليوم الأول، ووادي الملوك ومعبد حتشبسوت في اليوم الثاني.',
   3, 360.00, 8,
   array['2 nights hotel with breakfast', 'Karnak and Luxor temples entry', 'Valley of the Kings entry', 'Egyptologist guide'],
   array['ليلتان في فندق مع الإفطار', 'دخول معبدي الكرنك والأقصر', 'دخول وادي الملوك', 'مرشد أثري'], 1),
  ('luxor', 'Nile Cruise: Luxor to Aswan', 'رحلة نيلية من الأقصر إلى أسوان',
   'Sail upriver with guided stops at Edfu and Kom Ombo.',
   'إبحار في النيل جنوبًا مع زيارات مصحوبة بمرشد إلى إدفو وكوم أمبو.',
   5, 690.00, 4,
   array['4 nights cruise cabin, full board', 'Guided temple visits en route', 'Port transfers'],
   array['٤ ليالٍ في كابينة مع إقامة كاملة', 'زيارات للمعابد مع مرشد على الطريق', 'التنقل من وإلى الميناء'], 2),

  ('aswan', 'Aswan & Abu Simbel', 'أسوان وأبو سمبل',
   'Philae by boat, a felucca sail at sunset and a day trip to Abu Simbel.',
   'زيارة فيلة بالقارب وجولة بالفلوكة عند الغروب ورحلة يومية إلى أبو سمبل.',
   3, 410.00, 8,
   array['2 nights hotel with breakfast', 'Philae temple entry', 'Abu Simbel day trip', 'Felucca sail'],
   array['ليلتان في فندق مع الإفطار', 'دخول معبد فيلة', 'رحلة يومية إلى أبو سمبل', 'جولة بالفلوكة'], 1),
  ('aswan', 'Nubian Village Stay', 'إقامة في قرية نوبية',
   'An overnight stay with a Nubian family on the west bank of the Nile.',
   'ليلة مع عائلة نوبية على الضفة الغربية للنيل.',
   2, 190.00, 4,
   array['1 night guesthouse stay', 'Boat transfer to the west bank', 'Traditional dinner'],
   array['ليلة في بيت ضيافة', 'التنقل بالقارب إلى الضفة الغربية', 'عشاء تقليدي'], 2),

  ('sharm-el-sheikh', 'Red Sea Dive Week', 'أسبوع الغوص في البحر الأحمر',
   'Ten guided boat dives including Ras Mohammed and the Strait of Tiran. Certification required.',
   'عشر غطسات بالقارب مع مرشد تشمل رأس محمد ومضيق تيران. يلزم امتلاك شهادة غوص.',
   7, 980.00, 6,
   array['6 nights resort, half board', '10 guided boat dives', 'Ras Mohammed park fees', 'Equipment rental'],
   array['٦ ليالٍ في منتجع مع نصف إقامة', '١٠ غطسات بالقارب مع مرشد', 'رسوم محمية رأس محمد', 'استئجار المعدات'], 1),
  ('sharm-el-sheikh', 'Snorkel & Relax', 'غطس سطحي واسترخاء',
   'Easy reef days for all levels, with time to unwind on the beach.',
   'أيام سهلة بين الشعاب تناسب كل المستويات، مع وقت للاسترخاء على الشاطئ.',
   4, 520.00, 8,
   array['3 nights resort, half board', '2 snorkelling boat trips', 'Airport transfers'],
   array['٣ ليالٍ في منتجع مع نصف إقامة', 'رحلتا غطس سطحي بالقارب', 'التنقل من وإلى المطار'], 2),

  ('petra', 'Petra & Wadi Rum', 'البتراء ووادي رم',
   'Two days in Petra followed by a night under the stars in Wadi Rum.',
   'يومان في البتراء تليهما ليلة تحت النجوم في وادي رم.',
   4, 640.00, 8,
   array['3 nights (2 hotel, 1 desert camp)', '2-day Petra pass', 'Wadi Rum jeep tour', 'Private transfers'],
   array['٣ ليالٍ (ليلتان في فندق وليلة في مخيم صحراوي)', 'تذكرة البتراء ليومين', 'جولة بسيارات الدفع الرباعي في وادي رم', 'تنقلات خاصة'], 1),
  ('petra', 'Petra by Night', 'البتراء ليلًا',
   'A full day exploring Petra and the candle-lit Treasury after dark.',
   'يوم كامل لاستكشاف البتراء ومشاهدة الخزنة على ضوء الشموع ليلًا.',
   2, 310.00, 8,
   array['1 night hotel with breakfast', '1-day Petra pass', 'Petra by Night entry'],
   array['ليلة في فندق مع الإفطار', 'تذكرة البتراء ليوم واحد', 'دخول عرض البتراء ليلًا'], 2),

  ('istanbul', 'Classic Istanbul', 'إسطنبول الكلاسيكية',
   'The old city''s landmarks with a guide, plus a cruise along the Bosphorus.',
   'معالم المدينة القديمة مع مرشد، إضافة إلى جولة بحرية في البوسفور.',
   4, 560.00, 8,
   array['3 nights hotel in Sultanahmet', 'Old City guided walk', 'Bosphorus cruise', 'Airport transfers'],
   array['٣ ليالٍ في فندق بالسلطان أحمد', 'جولة سيرًا مع مرشد في المدينة القديمة', 'جولة بحرية في البوسفور', 'التنقل من وإلى المطار'], 1),
  ('istanbul', 'Istanbul Long Weekend', 'عطلة طويلة في إسطنبول',
   'Three days at your own pace with transport sorted.',
   'ثلاثة أيام على راحتك مع ترتيب المواصلات.',
   3, 390.00, 6,
   array['2 nights hotel with breakfast', 'Bosphorus cruise', 'Preloaded Istanbulkart for public transport'],
   array['ليلتان في فندق مع الإفطار', 'جولة بحرية في البوسفور', 'بطاقة إسطنبول كارت مشحونة للمواصلات'], 2),

  ('dubai', 'Dubai City & Desert', 'دبي بين المدينة والصحراء',
   'Skyline views from the Burj Khalifa and an evening desert safari.',
   'إطلالات على أفق المدينة من برج خليفة ورحلة سفاري صحراوية مسائية.',
   4, 790.00, 8,
   array['3 nights hotel with breakfast', 'Burj Khalifa observation deck', 'Desert safari with dinner', 'Airport transfers'],
   array['٣ ليالٍ في فندق مع الإفطار', 'منصة المشاهدة في برج خليفة', 'سفاري صحراوي مع العشاء', 'التنقل من وإلى المطار'], 1),
  ('dubai', 'Dubai Stopover', 'توقف قصير في دبي',
   'A one-night stopover with a walk through old Dubai and an abra crossing.',
   'توقف ليلة واحدة مع جولة في دبي القديمة وعبور الخور بالعَبرة.',
   2, 340.00, 6,
   array['1 night hotel with breakfast', 'Old Dubai and abra walking tour'],
   array['ليلة في فندق مع الإفطار', 'جولة سيرًا في دبي القديمة مع العَبرة'], 2),

  ('paris', 'Paris Essentials', 'أساسيات باريس',
   'The big museums with timed entry and an evening on the Seine.',
   'أبرز المتاحف بتذاكر محددة الموعد وأمسية على نهر السين.',
   4, 890.00, 6,
   array['3 nights hotel with breakfast', 'Louvre timed entry', 'Seine river cruise'],
   array['٣ ليالٍ في فندق مع الإفطار', 'دخول اللوفر بموعد محدد', 'جولة بحرية في نهر السين'], 1),
  ('paris', 'Paris & Versailles', 'باريس وفرساي',
   'Five days including a full day at the Palace of Versailles.',
   'خمسة أيام تتضمن يومًا كاملًا في قصر فرساي.',
   5, 1150.00, 6,
   array['4 nights hotel with breakfast', 'Palace of Versailles entry', 'Louvre timed entry', 'Return train to Versailles'],
   array['٤ ليالٍ في فندق مع الإفطار', 'دخول قصر فرساي', 'دخول اللوفر بموعد محدد', 'القطار ذهابًا وإيابًا إلى فرساي'], 2),

  ('rome', 'Rome in Four Days', 'روما في أربعة أيام',
   'Ancient Rome and the Vatican with skip-the-line timed entries.',
   'روما القديمة والفاتيكان بتذاكر محددة الموعد دون انتظار.',
   4, 780.00, 8,
   array['3 nights hotel with breakfast', 'Colosseum and Roman Forum entry', 'Vatican Museums timed entry'],
   array['٣ ليالٍ في فندق مع الإفطار', 'دخول الكولوسيوم والمنتدى الروماني', 'دخول متاحف الفاتيكان بموعد محدد'], 1),
  ('rome', 'Ancient Rome Weekend', 'عطلة روما القديمة',
   'A focused weekend on the Colosseum, the Forum and Palatine Hill.',
   'عطلة مركّزة على الكولوسيوم والمنتدى وتل بالاتين.',
   3, 520.00, 8,
   array['2 nights hotel with breakfast', 'Colosseum guided tour'],
   array['ليلتان في فندق مع الإفطار', 'جولة في الكولوسيوم مع مرشد'], 2),

  ('kyoto', 'Kyoto Temples & Gardens', 'معابد كيوتو وحدائقها',
   'Early-morning visits to the busiest sights and a traditional tea ceremony.',
   'زيارات صباحية مبكرة لأشهر المعالم وحفل شاي تقليدي.',
   5, 1240.00, 6,
   array['4 nights ryokan or hotel with breakfast', 'Guided Higashiyama walk', 'Fushimi Inari and Arashiyama day', 'Tea ceremony'],
   array['٤ ليالٍ في نُزل ياباني أو فندق مع الإفطار', 'جولة سيرًا مع مرشد في هيغاشيياما', 'يوم في فوشيمي إيناري وأراشيياما', 'حفل شاي'], 1),
  ('kyoto', 'Kyoto Highlights', 'أبرز معالم كيوتو',
   'Three self-guided days with transport included.',
   'ثلاثة أيام بلا مرشد مع تضمين المواصلات.',
   3, 720.00, 6,
   array['2 nights hotel with breakfast', 'City bus and subway pass', 'Kinkaku-ji entry'],
   array['ليلتان في فندق مع الإفطار', 'تذكرة الحافلات والمترو', 'دخول معبد كينكاكو-جي'], 2),

  ('bali', 'Ubud & the Coast', 'أوبود والساحل',
   'Rice terraces and temples inland, then sunset at Tanah Lot and two nights by the sea.',
   'مدرجات الأرز والمعابد في الداخل، ثم الغروب في تاناه لوت وليلتان على البحر.',
   6, 870.00, 8,
   array['5 nights (3 in Ubud, 2 by the beach)', 'Rice terrace and temple tour', 'Tanah Lot sunset visit', 'Private transfers'],
   array['٥ ليالٍ (٣ في أوبود و٢ على الشاطئ)', 'جولة في مدرجات الأرز والمعابد', 'زيارة تاناه لوت عند الغروب', 'تنقلات خاصة'], 1),
  ('bali', 'Mount Batur Sunrise', 'شروق الشمس على جبل باتور',
   'A pre-dawn guided trek to watch the sunrise from an active volcano.',
   'رحلة مشي مع مرشد قبل الفجر لمشاهدة الشروق من بركان نشط.',
   3, 380.00, 8,
   array['2 nights hotel in Ubud', 'Guided sunrise trek', 'Breakfast on the summit'],
   array['ليلتان في فندق بأوبود', 'رحلة مشي مع مرشد عند الشروق', 'إفطار على القمة'], 2),

  ('santorini', 'Santorini Caldera Escape', 'إقامة على حافة فوهة سانتوريني',
   'Caldera views, a boat trip to the volcano and the ruins of Akrotiri.',
   'إطلالات على الفوهة ورحلة بالقارب إلى البركان وأطلال أكروتيري.',
   4, 960.00, 4,
   array['3 nights caldera-view hotel with breakfast', 'Caldera boat cruise', 'Akrotiri site entry'],
   array['٣ ليالٍ في فندق مطل على الفوهة مع الإفطار', 'جولة بالقارب في الفوهة', 'دخول موقع أكروتيري'], 1),
  ('santorini', 'Santorini Weekend', 'عطلة نهاية أسبوع في سانتوريني',
   'Two nights with a guided hike from Fira to Oia for sunset.',
   'ليلتان مع رحلة مشي مصحوبة بمرشد من فيرا إلى أويا لمشاهدة الغروب.',
   3, 610.00, 6,
   array['2 nights hotel with breakfast', 'Fira–Oia guided hike'],
   array['ليلتان في فندق مع الإفطار', 'رحلة مشي مع مرشد من فيرا إلى أويا'], 2)
) as v(slug, name_en, name_ar, description_en, description_ar, duration_days, price, max_travelers, includes_en, includes_ar, sort_order)
join public.destinations d on d.slug = v.slug
on conflict (destination_id, name_en) do update set
  name_ar = excluded.name_ar,
  description_en = excluded.description_en,
  description_ar = excluded.description_ar,
  duration_days = excluded.duration_days,
  price_per_person = excluded.price_per_person,
  currency = excluded.currency,
  max_travelers = excluded.max_travelers,
  includes_en = excluded.includes_en,
  includes_ar = excluded.includes_ar,
  sort_order = excluded.sort_order,
  is_active = true;


-- -----------------------------------------------------------------------------
-- Catalog expansion (Phase 8): 8 more destinations and 16 more packages,
-- chosen to balance the categories (Beaches and Islands had only 1–2 each).
-- Same honesty rules as the header above: real facts, coordinates and
-- seasons; ILLUSTRATIVE prices; nothing invented. Images are Wikimedia Commons
-- Featured / Quality images; author and licence were read from the Commons
-- API and every URL was checked to return 200 image/jpeg on 2026-10-03.
-- -----------------------------------------------------------------------------
insert into public.destinations (
  slug, category_id, name_en, name_ar, country_en, country_ar,
  summary_en, summary_ar, description_en, description_ar,
  best_season_en, best_season_ar, latitude, longitude,
  cover_image, gallery, image_credit, is_featured
) values
(
  'algarve', 'beach', 'Algarve', 'الغارف', 'Portugal', 'البرتغال',
  'Golden cliffs, sea caves and coves on Portugal''s southern coast.',
  'منحدرات ذهبية وكهوف بحرية وخلجان على الساحل الجنوبي للبرتغال.',
  'The Algarve''s limestone coast is carved into arches, sea stacks and hidden coves such as Praia da Marinha. Kayak or take a boat into the Benagil sea cave, wander the old town of Lagos, and finish at Sagres and Cabo de São Vicente, the south-western tip of mainland Europe.',
  'نحتت الطبيعة ساحل الغارف الكلسي على شكل أقواس وصخور بحرية وخلجان مخفية مثل شاطئ مارينيا. يمكنك التجديف أو ركوب القارب إلى كهف بيناجيل البحري، والتجول في البلدة القديمة في لاغوش، ثم الوصول إلى ساغريش ورأس ساو فيسنتي، الطرف الجنوبي الغربي لبرّ أوروبا.',
  'May – June, September – October', 'مايو – يونيو، سبتمبر – أكتوبر', 37.0899, -8.4128,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/97/Praia_da_Marinha-Algarve-Portugal.jpg/1280px-Praia_da_Marinha-Algarve-Portugal.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b0/Ponta_de_Sagres_2024-12-20.jpg/1280px-Ponta_de_Sagres_2024-12-20.jpg', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1f/Praia_do_Tonel_2024-12-20.jpg/1280px-Praia_do_Tonel_2024-12-20.jpg'],
  'Wikimedia Commons: Tobi 87 (CC BY-SA 3.0); The Cosmonaut (CC BY-SA 2.5 CA)',
  false
),
(
  'zanzibar', 'beach', 'Zanzibar', 'زنجبار', 'Tanzania', 'تنزانيا',
  'Spice-island history, white-sand beaches and dhows at sunset.',
  'تاريخ جزيرة التوابل وشواطئ رملية بيضاء ومراكب شراعية عند الغروب.',
  'Stone Town, a UNESCO World Heritage Site, is a maze of carved wooden doors, Arab and Swahili houses and busy markets. Beyond it lie spice farms, the white beaches of Nungwi and Kendwa, and coral reefs that are easy to snorkel from a traditional dhow.',
  'ستون تاون موقع مدرج على قائمة اليونسكو للتراث العالمي، وهي متاهة من الأبواب الخشبية المنحوتة والبيوت العربية والسواحيلية والأسواق المزدحمة. وخارجها مزارع التوابل وشواطئ نونغوي وكيندوا البيضاء وشعاب مرجانية يسهل الغطس فيها من مركب شراعي تقليدي.',
  'June – October, December – February', 'يونيو – أكتوبر، ديسمبر – فبراير', -6.1622, 39.1921,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Dhow_boat_Zanzibar.jpg/1280px-Dhow_boat_Zanzibar.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Puerto_de_Stone_Town%2C_Zanz%C3%ADbar%2C_Tanzania%2C_2024-05-31%2C_DD_02.jpg/1280px-Puerto_de_Stone_Town%2C_Zanz%C3%ADbar%2C_Tanzania%2C_2024-05-31%2C_DD_02.jpg', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e8/An%C3%A9mona_magn%C3%ADfica_%28Radianthus_magnifica%29%2C_Zanz%C3%ADbar%2C_Tanzania%2C_2024-05-29%2C_DD_51.jpg/1280px-An%C3%A9mona_magn%C3%ADfica_%28Radianthus_magnifica%29%2C_Zanz%C3%ADbar%2C_Tanzania%2C_2024-05-29%2C_DD_51.jpg'],
  'Wikimedia Commons: Anton Zelenov (CC BY-SA 3.0); Diego Delso (CC BY-SA 4.0)',
  false
),
(
  'phuket', 'beach', 'Phuket', 'بوكيت', 'Thailand', 'تايلاند',
  'Andaman beaches and limestone islands in Phang Nga Bay.',
  'شواطئ بحر أندامان وجزر كلسية في خليج فانغ نغا.',
  'Thailand''s largest island mixes lively beaches like Patong with quieter Kata and Karon. Climb to the Big Buddha for views across the island, then take a long-tail boat into Phang Nga Bay, where limestone towers such as Ko Tapu rise straight out of the sea.',
  'تجمع أكبر جزر تايلاند بين شواطئ نابضة بالحياة مثل باتونغ وشواطئ أهدأ مثل كاتا وكارون. اصعد إلى تمثال بوذا الكبير لتطل على الجزيرة، ثم استقل قاربًا تقليديًا إلى خليج فانغ نغا حيث ترتفع أبراج كلسية مثل كو تابو مباشرة من البحر.',
  'November – April', 'نوفمبر – أبريل', 7.8804, 98.3923,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e3/Isla_Tapu%2C_Phuket%2C_Tailandia%2C_2013-08-20%2C_DD_36.JPG/1280px-Isla_Tapu%2C_Phuket%2C_Tailandia%2C_2013-08-20%2C_DD_36.JPG',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/5/56/The_Big_Buddha%2C_Phuket.jpg/1280px-The_Big_Buddha%2C_Phuket.jpg'],
  'Wikimedia Commons: Diego Delso (CC BY-SA 3.0); Subhrajyoti07 (CC BY-SA 4.0)',
  false
),
(
  'maldives', 'islands', 'Maldives', 'جزر المالديف', 'Maldives', 'المالديف',
  'Coral atolls, turquoise lagoons and villas over the water.',
  'جزر مرجانية وبحيرات فيروزية وفيلات فوق الماء.',
  'Around 1,200 coral islands form 26 atolls in the Indian Ocean. Many resorts occupy an island of their own and are reached by seaplane from Malé. The reefs are among the best for snorkelling, with turtles, reef sharks and, in season, manta rays.',
  'تشكّل نحو ١٢٠٠ جزيرة مرجانية ٢٦ حلقة مرجانية في المحيط الهندي. وكثير من المنتجعات يشغل جزيرة كاملة ويُوصل إليه بالطائرة المائية من ماليه. وتُعد شعابها من أفضل مواقع الغطس السطحي، حيث السلاحف وأسماك القرش المرجانية، وأسماك المانتا في موسمها.',
  'November – April', 'نوفمبر – أبريل', 4.1755, 73.5093,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ce/Floatplane_at_Bathala_%28Maldives%29.jpg/1280px-Floatplane_at_Bathala_%28Maldives%29.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c7/Diamonds_Thudufushi_Beach_and_Water_Villas%2C_May_2017_-03.jpg/1280px-Diamonds_Thudufushi_Beach_and_Water_Villas%2C_May_2017_-03.jpg'],
  'Wikimedia Commons: Gzzz (CC BY-SA 4.0); Martin Falbisoner (CC BY-SA 4.0)',
  true
),
(
  'mallorca', 'islands', 'Mallorca', 'مايوركا', 'Spain', 'إسبانيا',
  'A Gothic cathedral, mountain villages and turquoise coves.',
  'كاتدرائية قوطية وقرى جبلية وخلجان فيروزية.',
  'The largest of the Balearic Islands is crowned by Palma''s Gothic cathedral, La Seu. Drive the Serra de Tramuntana, a UNESCO World Heritage cultural landscape, to stone villages like Valldemossa and Deià, swim in clear coves, and watch the sunset from the lighthouse at Cap de Formentor.',
  'تتوّج أكبرَ جزر البليار كاتدرائيةُ بالما القوطية «لا سيو». قُد سيارتك في جبال ترامونتانا، المدرجة على قائمة اليونسكو كمشهد ثقافي، إلى قرى حجرية مثل فالديموسا وديا، واسبح في خلجان صافية، وشاهد الغروب من منارة رأس فورمينتور.',
  'May – June, September – October', 'مايو – يونيو، سبتمبر – أكتوبر', 39.5696, 2.6502,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e5/Cap_Formentor_2015_%28Zuschnitt%29.jpg/1280px-Cap_Formentor_2015_%28Zuschnitt%29.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/1/12/Kathedrale_von_Palma_II.jpg/1280px-Kathedrale_von_Palma_II.jpg', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9c/Cathedral_of_Mallorca_-_entrance.jpg/1280px-Cathedral_of_Mallorca_-_entrance.jpg'],
  'Wikimedia Commons: Thomas Wolf, www.foto-tw.de (CC BY-SA 3.0 DE); T meltzer (CC BY-SA 4.0)',
  false
),
(
  'marrakech', 'city', 'Marrakech', 'مراكش', 'Morocco', 'المغرب',
  'Souks, riads and the nightly spectacle of Jemaa el-Fna.',
  'أسواق ورياض وعروض ساحة جامع الفنا كل مساء.',
  'The medina of Marrakech, a UNESCO World Heritage Site, centres on Jemaa el-Fna square, where food stalls and storytellers gather every evening. Get lost in the souks, visit the Bahia Palace and the Koutoubia Mosque, rest in the Jardin Majorelle, and take a day trip into the High Atlas.',
  'تتمحور مدينة مراكش العتيقة، المدرجة على قائمة اليونسكو للتراث العالمي، حول ساحة جامع الفنا حيث تجتمع أكشاك الطعام والحكواتيون كل مساء. تجوّل في الأسواق، وزر قصر الباهية وجامع الكتبية، واسترح في حديقة ماجوريل، وقم برحلة يومية إلى جبال الأطلس الكبير.',
  'March – May, September – November', 'مارس – مايو، سبتمبر – نوفمبر', 31.6295, -7.9811,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d0/Oriental_hanging_lanterns._Souk_Haddadine%2C_Marrakech_Medina%2C_Morocco.jpg/1280px-Oriental_hanging_lanterns._Souk_Haddadine%2C_Marrakech_Medina%2C_Morocco.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7b/L%C3%A1mparas%2C_Djemaa_el_Fna_--_2014_--_Marrakech%2C_Marruecos.jpg/1280px-L%C3%A1mparas%2C_Djemaa_el_Fna_--_2014_--_Marrakech%2C_Marruecos.jpg'],
  'Wikimedia Commons: Petar Milošević (CC BY-SA 4.0); I. Barrios & J. Ligero (CC BY-SA 3.0)',
  true
),
(
  'singapore', 'city', 'Singapore', 'سنغافورة', 'Singapore', 'سنغافورة',
  'Garden-city skyline, hawker food and neighbourhoods full of character.',
  'أفق مدينة الحدائق وطعام الباعة وأحياء مليئة بالطابع الخاص.',
  'Singapore packs a lot into a small island: the Supertrees of Gardens by the Bay, the Marina Bay waterfront, and hawker centres whose food culture is recognised by UNESCO. Explore Chinatown, Little India and Kampong Glam on foot, then spend a day on Sentosa.',
  'تختصر سنغافورة الكثير في جزيرة صغيرة: الأشجار العملاقة في حدائق الخليج، وواجهة مارينا باي البحرية، ومراكز الباعة التي اعترفت اليونسكو بثقافة طعامها. استكشف الحي الصيني والهند الصغيرة وكامبونغ غلام سيرًا على الأقدام، ثم اقضِ يومًا في جزيرة سنتوسا.',
  'February – April', 'فبراير – أبريل', 1.2903, 103.8520,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/df/Puente_Helix%2C_museo_ArtScience_y_hotel_Marina_Bay_Sands%2C_Marina_Bay%2C_Singapur%2C_2023-08-17%2C_DD_67-69_HDR.jpg/1280px-Puente_Helix%2C_museo_ArtScience_y_hotel_Marina_Bay_Sands%2C_Marina_Bay%2C_Singapur%2C_2023-08-17%2C_DD_67-69_HDR.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b0/Singapore_Marina_Bay_Dusk_2018-02-27.jpg/1280px-Singapore_Marina_Bay_Dusk_2018-02-27.jpg'],
  'Wikimedia Commons: Diego Delso (CC BY-SA 4.0); Benh LIEU SONG (CC BY-SA 4.0)',
  false
),
(
  'machu-picchu', 'heritage', 'Machu Picchu', 'ماتشو بيتشو', 'Peru', 'بيرو',
  'The 15th-century Inca citadel high in the Andes.',
  'قلعة الإنكا من القرن الخامس عشر عاليًا في جبال الأنديز.',
  'Built by the Inca in the 15th century and a UNESCO World Heritage Site, Machu Picchu sits on a ridge above the Urubamba valley. Most visitors take the train from Cusco to Aguas Calientes; others walk the classic Inca Trail, whose permits are limited and sell out early.',
  'بناها الإنكا في القرن الخامس عشر وهي مدرجة على قائمة اليونسكو للتراث العالمي، وتقع ماتشو بيتشو على قمة جبلية فوق وادي أوروبامبا. يصل معظم الزوار بالقطار من كوسكو إلى أغواس كالينتيس، بينما يسلك آخرون درب الإنكا الكلاسيكي الذي تصاريحه محدودة وتنفد مبكرًا.',
  'April – October', 'أبريل – أكتوبر', -13.1631, -72.5450,
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/62/80_-_Machu_Picchu_-_Juin_2009_-_edit.jpg/1280px-80_-_Machu_Picchu_-_Juin_2009_-_edit.jpg',
  array['https://thumb.wikimedia.org/wikipedia/commons/thumb/7/71/Machu_Picchu%2C_Per%C3%BA%2C_2015-07-30%2C_DD_47.JPG/1280px-Machu_Picchu%2C_Per%C3%BA%2C_2015-07-30%2C_DD_47.JPG'],
  'Wikimedia Commons: Martin St-Amant (CC BY-SA 3.0); Diego Delso (CC BY-SA 4.0)',
  true
)
on conflict (slug) do update set
  category_id = excluded.category_id,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  country_en = excluded.country_en,
  country_ar = excluded.country_ar,
  summary_en = excluded.summary_en,
  summary_ar = excluded.summary_ar,
  description_en = excluded.description_en,
  description_ar = excluded.description_ar,
  best_season_en = excluded.best_season_en,
  best_season_ar = excluded.best_season_ar,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  cover_image = excluded.cover_image,
  gallery = excluded.gallery,
  image_credit = excluded.image_credit,
  is_featured = excluded.is_featured;

insert into public.destination_packages (
  destination_id, name_en, name_ar, description_en, description_ar,
  duration_days, price_per_person, currency, max_travelers, includes_en, includes_ar, sort_order
)
select d.id, v.name_en, v.name_ar, v.description_en, v.description_ar,
       v.duration_days, v.price, 'USD', v.max_travelers, v.includes_en, v.includes_ar, v.sort_order
from (values
  ('algarve', 'Algarve Coast & Caves', 'ساحل الغارف وكهوفه',
   'A boat trip to the Benagil cave, the Seven Hanging Valleys trail and two beach days.',
   'رحلة بالقارب إلى كهف بيناجيل، ومسار الوديان السبعة المعلقة، ويومان على الشاطئ.',
   5, 690.00, 8,
   array['4 nights hotel with breakfast', 'Benagil cave boat trip', 'Seven Hanging Valleys guided walk', 'Airport transfers'],
   array['٤ ليالٍ في فندق مع الإفطار', 'رحلة بالقارب إلى كهف بيناجيل', 'جولة مشي مع مرشد في مسار الوديان السبعة المعلقة', 'التنقل من وإلى المطار'], 1),
  ('algarve', 'Sagres & the West Coast', 'ساغريش والساحل الغربي',
   'Wild beaches, cliff-top walks and sunset at Cabo de São Vicente.',
   'شواطئ برية ومشي فوق المنحدرات والغروب عند رأس ساو فيسنتي.',
   3, 420.00, 8,
   array['2 nights guesthouse with breakfast', 'Guided coastal walk', 'Sunset at Cabo de São Vicente'],
   array['ليلتان في دار ضيافة مع الإفطار', 'جولة مشي ساحلية مع مرشد', 'الغروب عند رأس ساو فيسنتي'], 2),
  ('zanzibar', 'Stone Town & Spice Island', 'ستون تاون وجزيرة التوابل',
   'Old-town walks, a spice-farm tour and a sunset dhow cruise.',
   'جولات في البلدة القديمة وزيارة مزرعة توابل ورحلة غروب بمركب شراعي.',
   5, 780.00, 8,
   array['4 nights (2 Stone Town, 2 beach)', 'Guided Stone Town walk', 'Spice farm tour', 'Sunset dhow cruise'],
   array['٤ ليالٍ (ليلتان في ستون تاون وليلتان على الشاطئ)', 'جولة مشي مع مرشد في ستون تاون', 'زيارة مزرعة توابل', 'رحلة غروب بمركب شراعي'], 1),
  ('zanzibar', 'Nungwi Beach Escape', 'عطلة شاطئ نونغوي',
   'Beach days in the north of the island with a snorkelling trip.',
   'أيام على الشاطئ في شمال الجزيرة مع رحلة غطس سطحي.',
   4, 560.00, 6,
   array['3 nights beach hotel, half board', 'Snorkelling boat trip', 'Airport transfers'],
   array['٣ ليالٍ في فندق شاطئي مع نصف إقامة', 'رحلة غطس سطحي بالقارب', 'التنقل من وإلى المطار'], 2),
  ('phuket', 'Phuket & Phang Nga Bay', 'بوكيت وخليج فانغ نغا',
   'Beach days plus a full-day long-tail boat trip among the limestone islands.',
   'أيام على الشاطئ ورحلة يوم كامل بالقارب التقليدي بين الجزر الكلسية.',
   5, 640.00, 8,
   array['4 nights hotel with breakfast', 'Phang Nga Bay boat trip', 'Big Buddha visit', 'Airport transfers'],
   array['٤ ليالٍ في فندق مع الإفطار', 'رحلة بالقارب في خليج فانغ نغا', 'زيارة تمثال بوذا الكبير', 'التنقل من وإلى المطار'], 1),
  ('phuket', 'Andaman Island Hopping', 'التنقل بين جزر أندامان',
   'A speedboat day to the Phi Phi Islands and a quieter beach stay.',
   'يوم بالقارب السريع إلى جزر في في وإقامة على شاطئ أهدأ.',
   4, 520.00, 8,
   array['3 nights hotel with breakfast', 'Phi Phi Islands speedboat trip', 'Snorkelling gear'],
   array['٣ ليالٍ في فندق مع الإفطار', 'رحلة بالقارب السريع إلى جزر في في', 'معدات الغطس السطحي'], 2),
  ('maldives', 'Water Villa Retreat', 'إقامة في فيلا فوق الماء',
   'Four nights over the lagoon with seaplane transfers and guided snorkelling.',
   'أربع ليالٍ فوق البحيرة مع التنقل بالطائرة المائية وغطس سطحي مع مرشد.',
   5, 1890.00, 4,
   array['4 nights water villa, half board', 'Return seaplane transfers', 'Guided house-reef snorkel'],
   array['٤ ليالٍ في فيلا فوق الماء مع نصف إقامة', 'التنقل ذهابًا وإيابًا بالطائرة المائية', 'غطس سطحي مع مرشد عند الشعاب المحيطة'], 1),
  ('maldives', 'Local Island Snorkel Week', 'أسبوع الغطس في جزيرة محلية',
   'A guesthouse stay on an inhabited island with daily boat excursions.',
   'إقامة في دار ضيافة على جزيرة مأهولة مع رحلات يومية بالقارب.',
   7, 1450.00, 6,
   array['6 nights guesthouse with breakfast', '3 snorkelling excursions', 'Sandbank picnic', 'Speedboat transfers from Malé'],
   array['٦ ليالٍ في دار ضيافة مع الإفطار', '٣ رحلات غطس سطحي', 'نزهة على شريط رملي', 'التنقل بالقارب السريع من ماليه'], 2),
  ('mallorca', 'Palma & the Tramuntana', 'بالما وجبال ترامونتانا',
   'Palma''s old town and cathedral, then the mountain road to Valldemossa and Deià.',
   'بلدة بالما القديمة وكاتدرائيتها، ثم الطريق الجبلي إلى فالديموسا وديا.',
   5, 760.00, 8,
   array['4 nights hotel with breakfast', 'Cathedral entry', 'Tramuntana day tour', 'Airport transfers'],
   array['٤ ليالٍ في فندق مع الإفطار', 'دخول الكاتدرائية', 'جولة يومية في جبال ترامونتانا', 'التنقل من وإلى المطار'], 1),
  ('mallorca', 'Mallorca Coves by Boat', 'خلجان مايوركا بالقارب',
   'A short break with a boat day around the island''s clearest coves.',
   'عطلة قصيرة مع يوم بالقارب حول أصفى خلجان الجزيرة.',
   3, 430.00, 8,
   array['2 nights hotel with breakfast', 'Full-day coves boat trip with lunch'],
   array['ليلتان في فندق مع الإفطار', 'رحلة يوم كامل بالقارب بين الخلجان مع الغداء'], 2),
  ('marrakech', 'Medina & Majorelle', 'المدينة العتيقة وحديقة ماجوريل',
   'A guided medina walk, palaces and gardens, with a riad stay.',
   'جولة مع مرشد في المدينة العتيقة وزيارة القصور والحدائق مع الإقامة في رياض.',
   4, 480.00, 8,
   array['3 nights riad with breakfast', 'Guided medina and souk walk', 'Bahia Palace and Jardin Majorelle entry'],
   array['٣ ليالٍ في رياض مع الإفطار', 'جولة مع مرشد في المدينة العتيقة والأسواق', 'دخول قصر الباهية وحديقة ماجوريل'], 1),
  ('marrakech', 'Marrakech & the Atlas', 'مراكش وجبال الأطلس',
   'The medina plus a day in the High Atlas villages with a local guide.',
   'المدينة العتيقة ويوم في قرى الأطلس الكبير مع مرشد محلي.',
   5, 620.00, 8,
   array['4 nights riad with breakfast', 'High Atlas day trip with lunch', 'Guided medina walk', 'Airport transfers'],
   array['٤ ليالٍ في رياض مع الإفطار', 'رحلة يومية إلى الأطلس الكبير مع الغداء', 'جولة مشي مع مرشد في المدينة العتيقة', 'التنقل من وإلى المطار'], 2),
  ('singapore', 'Singapore City Highlights', 'أبرز معالم سنغافورة',
   'Gardens by the Bay, Marina Bay and a hawker-centre food walk.',
   'حدائق الخليج ومارينا باي وجولة طعام في مراكز الباعة.',
   4, 890.00, 6,
   array['3 nights hotel with breakfast', 'Gardens by the Bay conservatories entry', 'Hawker food walk with a guide'],
   array['٣ ليالٍ في فندق مع الإفطار', 'دخول بيوت النباتات في حدائق الخليج', 'جولة طعام مع مرشد في مراكز الباعة'], 1),
  ('singapore', 'Gardens & Sentosa', 'الحدائق وسنتوسا',
   'A short stay with a day on Sentosa island.',
   'إقامة قصيرة مع يوم في جزيرة سنتوسا.',
   3, 640.00, 6,
   array['2 nights hotel with breakfast', 'Sentosa day pass with cable car'],
   array['ليلتان في فندق مع الإفطار', 'تذكرة يومية لسنتوسا مع التلفريك'], 2),
  ('machu-picchu', 'Cusco & Machu Picchu', 'كوسكو وماتشو بيتشو',
   'Time to acclimatise in Cusco and the Sacred Valley, then the train to Machu Picchu.',
   'وقت للتأقلم مع الارتفاع في كوسكو والوادي المقدس، ثم القطار إلى ماتشو بيتشو.',
   5, 1180.00, 8,
   array['4 nights hotels with breakfast', 'Sacred Valley tour', 'Return train to Aguas Calientes', 'Machu Picchu entry and guide'],
   array['٤ ليالٍ في فنادق مع الإفطار', 'جولة في الوادي المقدس', 'القطار ذهابًا وإيابًا إلى أغواس كالينتيس', 'دخول ماتشو بيتشو مع مرشد'], 1),
  ('machu-picchu', 'Classic Inca Trail', 'درب الإنكا الكلاسيكي',
   'The four-day trek to the Sun Gate. Permits are limited and must be secured early.',
   'رحلة المشي لأربعة أيام حتى بوابة الشمس. التصاريح محدودة ويجب حجزها مبكرًا.',
   6, 1390.00, 8,
   array['2 nights hotel in Cusco', '3 nights camping on the trail', 'Trail permit, guides and porters', 'Return train to Cusco'],
   array['ليلتان في فندق بكوسكو', '٣ ليالٍ تخييم على الدرب', 'تصريح الدرب والمرشدون والحمّالون', 'القطار عائدًا إلى كوسكو'], 2)
) as v(slug, name_en, name_ar, description_en, description_ar, duration_days, price, max_travelers, includes_en, includes_ar, sort_order)
join public.destinations d on d.slug = v.slug
on conflict (destination_id, name_en) do update set
  name_ar = excluded.name_ar,
  description_en = excluded.description_en,
  description_ar = excluded.description_ar,
  duration_days = excluded.duration_days,
  price_per_person = excluded.price_per_person,
  currency = excluded.currency,
  max_travelers = excluded.max_travelers,
  includes_en = excluded.includes_en,
  includes_ar = excluded.includes_ar,
  sort_order = excluded.sort_order,
  is_active = true;

commit;

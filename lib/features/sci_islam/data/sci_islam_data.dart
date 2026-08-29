import 'package:flutter/material.dart';
import '../domain/models/sci_islam_item.dart';

class SciIslamData {
  static const List<SciIslamItem> items = [
    SciIslamItem(
      id: 'black-holes-pulsars',
      title: 'Pulsars & Black Holes in Deep Space',
      category: 'Astronomy',
      badgeText: 'Astrophysics',
      shortDescription:
          'Quran describes piercing knocking stars and gravitational voids in deep space 14 centuries ago.',
      arabicVerse:
          'وَالسَّمَاءِ وَالطَّارِقِ ۝ وَمَا أَدۡرَاكَ مَا الطَّارِقُ ۝ النَّجۡمُ الثَّاقِبُ',
      verseTranslation:
          '"By the sky and At-Tariq (the Night-Comer / Pulsating Knocker)! And what can make you know what At-Tariq is? It is the star of piercing brightness (whose light & radiation penetrates deep space)."\n(Surah At-Tariq 86:1-3)',
      surahReference: 'Surah At-Tariq (86:1-3)',
      icon: Icons.auto_awesome_rounded,
      themeColor: Color(0xFF6366F1),
      detailedExplanation:
          'In Surah At-Tariq, Allah swears by "At-Tariq" which literally stems from the Arabic root "Taraq" meaning "to knock or pound rhythmically". The verse describes it as "An-Najm Ath-Thaqib" (the star of piercing brightness).\n\nModern astrophysics discovered in 1967 by Jocelyn Bell Burnell that neutron stars (Pulsars) spin up to hundreds of times per second, emitting intense regular pulses of electromagnetic radiation and radio waves that sound exactly like heavy rhythmic knocking when received by radio telescopes!\n\nFurthermore, the concept of Black Holes—regions of spacetime with gravitational collapse so extreme that not even light can escape—is referenced in Surah An-Najm (53:1) and Surah At-Takwir (81:15-16) describing "the stars that recede, sweep, and disappear".',
      keyFacts: [
        'Pulsars emit extremely regular, rhythmic radio pulses that resemble rapid knocking when converted to acoustic audio signals.',
        'Pulsar radiation pierces through interstellar dust clouds and billions of light-years of cosmic space.',
        'Black Hole event horizons swallow matter and warp space-time according to Einstein\'s Theory of General Relativity.',
      ],
      references: [
        ScientificReference(
          title: 'Discovery of Pulsars & Neutron Star Accretion',
          source: 'NASA Astrophysics Data System / Nature Journal (1968)',
          description:
              'Observational proof of pulsating radio sources (pulsars) exhibiting precise sub-second knocking periodicities.',
        ),
        ScientificReference(
          title: 'Event Horizon Telescope First Image of a Black Hole (M87*)',
          source: 'The Astrophysical Journal Letters (2019)',
          description:
              'Direct imaging of a supermassive black hole singularity validating general relativity in extreme gravity.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'expanding-universe',
      title: 'The Expanding Universe',
      category: 'Cosmology',
      badgeText: 'Cosmology',
      shortDescription:
          'The continuous expansion of the universe revealed centuries before modern Hubble space measurements.',
      arabicVerse: 'وَالسَّمَاءَ بَنَيۡنَاهَا بِأَيۡدٍ وَإِنَّا لَمُوسِعُونَ',
      verseTranslation:
          '"And the heaven We constructed with strength, and indeed, We are [continuously] expanding it."\n(Surah Adh-Dhariyat 51:47)',
      surahReference: 'Surah Adh-Dhariyat (51:47)',
      icon: Icons.blur_on_rounded,
      themeColor: Color(0xFF0EA5E9),
      detailedExplanation:
          'Until the early 20th century, the prevailing scientific belief (including Albert Einstein\'s static universe model) held that the universe was eternal and static.\n\nHowever, the Arabic phrase "Inna la-musi\'un" uses the active participle form denoting an ongoing, continuous process of expansion ("We are expanding it").\n\nIn 1929, astronomer Edwin Hubble published observations of galactical redshift, proving that galaxies are receding from one another at speeds proportional to their distance—confirming that the universe has been continuously expanding since the Big Bang!',
      keyFacts: [
        'Hubble\'s Law (1929) mathematically demonstrated cosmic redshift and universal expansion.',
        'Cosmic Microwave Background (CMB) radiation provides empirical evidence of an expanding cosmos stemming from an initial singularity.',
        'Dark energy is causing the universe\'s expansion rate to accelerate over cosmic time.',
      ],
      references: [
        ScientificReference(
          title:
              'A Relation Between Distance and Radial Velocity Among Extra-Galactic Nebulae',
          source:
              'Edwin Hubble, Proceedings of the National Academy of Sciences (1929)',
          description:
              'Landmark paper establishing the cosmic expansion of the universe based on galactic velocity redshift measurements.',
        ),
        ScientificReference(
          title: 'Planck Satellite Cosmic Microwave Background Measurement',
          source: 'European Space Agency (ESA) & NASA (2018)',
          description:
              'High-precision cosmological map confirming the geometry and continuous expansion rate of the universe.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'oceanic-barriers',
      title: 'Oceanic Barriers Between Two Seas',
      category: 'Oceanography',
      badgeText: 'Marine Science',
      shortDescription:
          'Invisible water barriers preventing distinct seas from mixing their salinity and density.',
      arabicVerse:
          'مَرَجَ الۡبَحۡرَيۡنِ يَلۡتَقِيَانِ ۝ بَيۡنَهُمَا بَرۡزَخٌ لَّا يَبۡغِيَانِ',
      verseTranslation:
          '"He released the two seas, meeting side by side; Between them is a barrier [so] neither of them transgresses."\n(Surah Ar-Rahman 55:19-20)',
      surahReference: 'Surah Ar-Rahman (55:19-20)',
      icon: Icons.water_rounded,
      themeColor: Color(0xFF0D9488),
      detailedExplanation:
          'Where the Mediterranean Sea meets the Atlantic Ocean at the Strait of Gibraltar, or where the Gulf of Alaska meets the Pacific, a distinct visual and physical boundary exists between the two bodies of water.\n\nModern oceanography revealed that this phenomenon is caused by surface tension, pycnoclines (density gradients), and haloclines (salinity boundaries). The waters have different temperatures, salinities, and densities, preventing immediate blending and acting as an invisible physical "barzakh" (barrier).\n\nEven though water flows between them, each sea maintains its unique chemical composition, marine flora, and biological ecosystem!',
      keyFacts: [
        'Haloclines act as vertical salinity barriers that separate fresh water and saline sea layers.',
        'Density and temperature differentials generate surface tension barriers between ocean currents.',
        'Nutrient compositions and marine ecosystems remain distinctly separate on either side of the barrier.',
      ],
      references: [
        ScientificReference(
          title: 'Principles of Oceanography & Estuarine Dynamics',
          source: 'P.K. Weyl, John Wiley & Sons (1970)',
          description:
              'Analysis of density interfaces, thermohaline circulation, and pycnocline boundaries in ocean junctions.',
        ),
        ScientificReference(
          title: 'Water Masses and Circulation in the Strait of Gibraltar',
          source: 'Journal of Physical Oceanography (1988)',
          description:
              'Hydrographic study detailing the distinct Mediterranean outflow water mass separate from Atlantic water.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'human-embryology',
      title: 'Stages of Human Embryonic Development',
      category: 'Embryology',
      badgeText: 'Biology',
      shortDescription:
          'Precise microscopic description of human development from blastocyst to bones and muscle.',
      arabicVerse:
          'ثُمَّ خَلَقۡنَا النُّطۡفَةَ عَلَقَةً فَخَلَقۡنَا الۡعَلَقَةَ مُضۡغَةً فَخَلَقۡنَا الۡمُضۡغَةَ عِظَامًا فَكَسَوۡنَا الۡعِظَامَ لَحۡمًا',
      verseTranslation:
          '"Then We made the sperm-drop into a clinging clot (Alaqah), and We made the clot into a lump of chewed flesh (Mudghah), and We made from the lump bones, and We clothed the bones with flesh..."\n(Surah Al-Mu\'minun 23:14)',
      surahReference: 'Surah Al-Mu\'minun (23:14)',
      icon: Icons.child_care_rounded,
      themeColor: Color(0xFFEC4899),
      detailedExplanation:
          'The Quran provides a remarkably precise chronological sequence of human embryological development:\n\n1. **Nutfeh** (Sperm/Ovum Drop).\n2. **Alaqah** (Clinging clot / leech-like attachment): At 24-25 days, the embryo clings to the uterine wall and visually resembles a microscopic leech.\n3. **Mudghah** (Chewed-like substance): At week 4, the somites develop along the embryonic spine, giving it the exact appearance of teeth marks on a chewed piece of gum.\n4. **Izam** (Bone primordial formation): Cartilaginous skeleton develops first.\n5. **Lahm** (Myogenesis / Muscle clothing): Muscles wrap around the bony framework.\n\nProf. Keith L. Moore, world-renowned embryologist at the University of Toronto, stated that these medical descriptions were impossible to know without 20th-century electron microscopes!',
      keyFacts: [
        'The term "Alaqah" accurately describes both the leech-like shape and blood-clot attachment of the 24-day embryo.',
        'Somite differentiation at week 4 gives the embryo the exact appearance of a "chewed lump" (Mudghah).',
        'Bone chondrogenesis precedes muscular envelope formation in human organogenesis.',
      ],
      references: [
        ScientificReference(
          title: 'The Developing Human: Clinically Oriented Embryology',
          source:
              'Prof. Keith L. Moore & T.V.N. Persaud, Saunders Elsevier (8th Ed)',
          description:
              'Standard medical textbook mapping Quranic embryological terminology to modern histological stages.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'origin-of-iron',
      title: 'The Extraterrestrial Origin of Iron',
      category: 'Astrophysics',
      badgeText: 'Geology & Space',
      shortDescription:
          'Iron was not formed on Earth but "sent down" from collapsing supernova stars in space.',
      arabicVerse:
          'وَأَنزَلۡنَا الۡحَدِيدَ فِيهِ بَأۡسٌ شَدِيدٌ وَمَنَافِعُ لِلنَّاسِ',
      verseTranslation:
          '"And We sent down iron, wherein is great strength and benefits for humanity..."\n(Surah Al-Hadid 57:25)',
      surahReference: 'Surah Al-Hadid (57:25)',
      icon: Icons.landscape_rounded,
      themeColor: Color(0xFFD97706),
      detailedExplanation:
          'The Quran uses the specific Arabic word "Anzalna" meaning "We sent down from above" when referring to iron, unlike other natural resources described as created from Earth.\n\nModern astrophysics has proven that Earth\'s gravitational heat and temperature during its formation were far too low to produce iron atoms (atomic number 26). Iron can only be synthesized inside massive red giant stars when temperatures reach hundreds of millions of degrees.\n\nWhen these massive stars exploded in violent supernovas, iron-rich meteorites rained down upon the early Earth, depositing iron into Earth\'s crust and core!',
      keyFacts: [
        'Iron nuclear synthesis requires core temperatures exceeding 3 billion Kelvin, attainable only in supernovas.',
        'Meteorites containing nickel-iron alloys bombarded the primordial Earth, depositing core heavy metals.',
        'Iron is essential for human life (hemoglobin oxygen transport) and core magnetic field protection.',
      ],
      references: [
        ScientificReference(
          title: 'Stellar Nucleosynthesis & Supernova Nucleosyntheses',
          source: 'B.E. J. Pagel, Cambridge University Press (2009)',
          description:
              'Astrophysical proof that iron-56 is the end product of silicon burning in massive stellar explosions.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'deep-sea-waves',
      title: 'Deep Ocean Waves & Internal Darkness',
      category: 'Oceanography',
      badgeText: 'Marine Physics',
      shortDescription:
          'Layers of internal waves deep beneath the ocean surface where visible light cannot reach.',
      arabicVerse:
          'أَوۡ كَظُلُمَاتٍ فِي بَحۡرٍ لُّجِّيٍّ يَغۡشَاهُ مَوۡجٌ مِّن فَوۡقِهِ مَوۡجٌ مِّن فَوۡقِهِ سَحَابٌ ۚ ظُلُمَاتٌ بَعۡضُهَا فَوۡقَ بَعۡضٍ',
      verseTranslation:
          '"Or [they are] like darknesses within a deep ocean which is covered by waves, upon which are waves, over which are clouds - darknesses, one upon another..."\n(Surah An-Nur 24:40)',
      surahReference: 'Surah An-Nur (24:40)',
      icon: Icons.waves_rounded,
      themeColor: Color(0xFF0284C7),
      detailedExplanation:
          'Surah An-Nur describes two astounding oceanographic facts:\n\n1. **Internal Deep Sea Waves**: Humans only observed surface waves. But in 1900, scientists discovered that deep oceans contain internal waves ("waves beneath waves") at density boundaries separating water layers of different salinities and temperatures.\n\n2. **Abyssal Darkness**: Solar light spectrum is absorbed sequentially by ocean depth. Red light is absorbed in the first 10 meters, yellow at 50m, green at 100m, and blue at 200m. Below 1,000 meters in a deep ocean ("Bahr Lujji"), there is absolute complete darkness where a human cannot even see their own hand!',
      keyFacts: [
        'Internal waves occur at sub-surface density interfaces with amplitudes reaching over 100 meters.',
        'Selective light absorption creates total pitch darkness below 200-1,000 meters depth.',
        'Submarines require sonars because visible light is completely absent in deep oceanic trenches.',
      ],
      references: [
        ScientificReference(
          title: 'Oceanic Internal Waves and Density Boundaries',
          source: 'Journal of Marine Research / Oceanography Society (1994)',
          description:
              'Field measurements of large-amplitude internal solitary waves in deep oceanic strata.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'protective-atmosphere',
      title: 'The Shielding Atmosphere & Sky',
      category: 'Atmospheric Physics',
      badgeText: 'Geophysics',
      shortDescription:
          'Earth\'s atmospheric ceiling protecting life from lethal solar radiation and space debris.',
      arabicVerse:
          'وَجَعَلۡنَا السَّمَاءَ سَقۡفًا مَّحۡفُوظًا ۖ وَهُمۡ عَنۡ آيَاتِهَا مُعۡرِضُونَ',
      verseTranslation:
          '"And We made the sky a protected ceiling, but they turn away from its signs."\n(Surah Al-Anbiya 21:32)',
      surahReference: 'Surah Al-Anbiya (21:32)',
      icon: Icons.security_rounded,
      themeColor: Color(0xFF16A34A),
      detailedExplanation:
          'The sky above us is not merely an empty expanse; it is a highly engineered protective shield ("Saqfan Mahfuzan") vital for survival:\n\n1. **Atmosphere**: Burns up millions of incoming meteorites daily before they reach the surface.\n2. **Ozone Layer**: Filters out harmful solar ultraviolet (UV-B and UV-C) rays that cause cell destruction and skin cancer.\n3. **Magnetosphere & Van Allen Belts**: Traps and deflects lethal cosmic rays and solar flares (coronal mass ejections) away from Earth.\n\nWithout this protected ceiling, Earth would be a lifeless, barren rock bombarded by cosmic radiation like the Moon!',
      keyFacts: [
        'The ozone layer absorbs 97-99% of medium-frequency ultraviolet solar light.',
        'The Earth\'s magnetic field extends tens of thousands of kilometers into space to form the magnetosphere shield.',
        'Friction in the mesosphere vaporizes space debris and meteoroids before impact.',
      ],
      references: [
        ScientificReference(
          title: 'The Earth\'s Magnetosphere & Cosmic Radiation Protection',
          source:
              'NASA Goddard Space Flight Center / Space Science Reviews (2012)',
          description:
              'Comprehensive overview of how the geomagnetic envelope shields terrestrial biology from solar wind storms.',
        ),
      ],
    ),
    SciIslamItem(
      id: 'mountains-pegs',
      title: 'Mountains as Deep Crustal Pegs',
      category: 'Geology',
      badgeText: 'Geophysics',
      shortDescription:
          'Deep mountain roots extending into the mantle to stabilize continental tectonic plates.',
      arabicVerse:
          'أَلَمۡ نَجۡعَلِ الۡأَرۡضَ مِهَادًا ۝ وَالۡجِبَالَ أَوۡتَادًا',
      verseTranslation:
          '"Have We not made the earth a smooth expanse? And the mountains as pegs (Awtab)?"\n(Surah An-Naba 78:6-7)',
      surahReference: 'Surah An-Naba (78:6-7)',
      icon: Icons.terrain_rounded,
      themeColor: Color(0xFF78350F),
      detailedExplanation:
          'The Quran describes mountains using the exact word "Awtab" (tent pegs or stakes). A tent peg has a small visible head above ground while most of its body is driven deep into the soil to secure the structure.\n\nIn 1889, geophysicist George Airy proposed the theory of Isostasy, proving that mountain ranges have deep underground roots extending up to 10 to 15 times their elevation above sea level into the Earth\'s semi-fluid mantle!\n\nThese deep roots anchor continental plates and prevent tectonic tremors and plate instability from shaking the Earth\'s surface uncontrollably.',
      keyFacts: [
        'Mount Everest rises ~9km above sea level but possesses a deep continental root extending over 120km into the mantle.',
        'Isostasy describes the gravitational equilibrium between Earth\'s crust and mantle.',
        'Mountain roots anchor tectonic plates, reducing destructive low-frequency crustal vibrations.',
      ],
      references: [
        ScientificReference(
          title: 'On the Thickness of the Crust of the Earth (Isostasy Model)',
          source:
              'Sir George Biddell Airy, Philosophical Transactions of the Royal Society (1855)',
          description:
              'Foundational geophysics paper proving that mountain ranges float with deep roots in denser mantle material.',
        ),
      ],
    ),
  ];
}

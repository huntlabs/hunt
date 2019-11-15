text_src = [
    'CharacterData/CharacterData.d',
    'CharacterData/CharacterDataLatin1.d',
    'CharacterData/package.d',
    'Charset.d',
    'Codec.d',
    'Common.d',
    'FormatterWrapper.d',
    'package.d',
    'PathMatcher.d',
    'Pattern.d',
    'PatternMatchUtils.d',
    'QuotedStringTokenizer.d',
    'QuoteUtil.d',
    'SearchPattern.d',
    'StringBuilder.d',
    'StringTokenizer.d',
    'StringUtils.d',
]


text_lib = library('hunt-text',
    text_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(text_lib,
              name: 'hunt-text',
              subdirs: 'd/hunt/hunt/text',
              version: meson.project_version(),
              description: 'Hunt text library.',
              d_module_versions: d_mod_version,
)

import 'text_utils.dart';

/// Género asignado cuando las etiquetas no permiten deducir uno concreto.
const String genreVariado = 'Variado';

/// Reglas para deducir el género a partir de las etiquetas de Radio Browser.
/// Se evalúan en orden: la primera que coincide gana.
const List<(String, List<String>)> _genreRules = [
  ('Noticias', ['news', 'noticia', 'informativ', 'talk', 'politic', 'actualidad']),
  ('Deportes', ['sport', 'deporte', 'futbol', 'soccer']),
  ('Cumbia', ['cumbia', 'chicha', 'tropical']),
  ('Salsa', ['salsa', 'timba']),
  ('Folklore', ['folk', 'huayno', 'andina', 'andino', 'andean', 'crioll', 'afroperuan', 'vals']),
  ('Urbano', ['reggaeton', 'regueton', 'urban', 'hip hop', 'trap', 'dembow']),
  ('Baladas', ['balada', 'romantic', 'bolero']),
  ('Rock & Pop', ['rock', 'pop', 'hits', 'top 40', '80s', '90s', 'oldies', 'retro', 'alternative', 'indie']),
];

/// Departamentos del Perú y las ciudades o provincias con las que suelen
/// aparecer en el campo `state` de Radio Browser.
const Map<String, List<String>> _regionKeywords = {
  'Amazonas': ['amazonas', 'chachapoyas', 'bagua', 'jumbilla'],
  'Áncash': ['ancash', 'huaraz', 'chimbote', 'casma', 'huarmey'],
  'Apurímac': ['apurimac', 'abancay', 'andahuaylas', 'chalhuanca'],
  'Arequipa': ['arequipa', 'camana', 'mollendo'],
  'Ayacucho': ['ayacucho', 'huamanga', 'huanta'],
  'Cajamarca': ['cajamarca', 'jaen', 'chota'],
  'Callao': ['callao'],
  'Cusco': ['cusco', 'cuzco', 'quillabamba', 'sicuani'],
  'Huancavelica': ['huancavelica'],
  'Huánuco': ['huanuco', 'tingo maria'],
  'Ica': ['ica', 'chincha', 'pisco', 'nazca', 'nasca'],
  'Junín': ['junin', 'huancayo', 'tarma', 'jauja', 'la merced', 'satipo'],
  'La Libertad': ['la libertad', 'trujillo', 'chepen', 'pacasmayo', 'huamachuco'],
  'Lambayeque': ['lambayeque', 'chiclayo', 'ferrenafe'],
  'Lima': ['lima', 'barranca', 'huacho', 'canete', 'huaral', 'chancay'],
  'Loreto': ['loreto', 'iquitos', 'yurimaguas'],
  'Madre de Dios': ['madre de dios', 'puerto maldonado'],
  'Moquegua': ['moquegua', 'ilo'],
  'Pasco': ['pasco', 'oxapampa'],
  'Piura': ['piura', 'sullana', 'talara', 'paita'],
  'Puno': ['puno', 'juliaca', 'azangaro'],
  'San Martín': ['san martin', 'tarapoto', 'moyobamba', 'uchiza', 'juanjui', 'rioja'],
  'Tacna': ['tacna', 'tarata'],
  'Tumbes': ['tumbes'],
  'Ucayali': ['ucayali', 'pucallpa'],
};

/// Las palabras clave de región se buscan como palabras completas para que,
/// por ejemplo, "ica" no coincida dentro de "música".
final Map<String, List<RegExp>> _regionPatterns = {
  for (final entry in _regionKeywords.entries)
    entry.key: [
      for (final keyword in entry.value) RegExp('\\b${RegExp.escape(keyword)}\\b'),
    ],
};

/// Deduce el género principal de una emisora a partir de sus etiquetas y su
/// nombre. Devuelve [genreVariado] si no hay coincidencias.
String inferGenre(String tags, String name) {
  final text = normalizeText('$tags $name');
  for (final (genre, keywords) in _genreRules) {
    if (keywords.any(text.contains)) return genre;
  }
  return genreVariado;
}

/// Deduce el departamento del Perú a partir del texto libre del campo
/// `state` de Radio Browser. Devuelve una cadena vacía si no lo reconoce.
String inferRegion(String state) {
  final text = normalizeText(state);
  if (text.isEmpty) return '';
  for (final entry in _regionPatterns.entries) {
    if (entry.value.any((pattern) => pattern.hasMatch(text))) return entry.key;
  }
  return '';
}

final RegExp _frequencyPattern =
    RegExp(r'(\d{2,4}(?:[.,]\d)?)\s*(fm|am)\b', caseSensitive: false);

/// Extrae la frecuencia ("89.7 FM", "620 AM") del nombre de la emisora si la
/// incluye.
String extractFrequency(String name) {
  final match = _frequencyPattern.firstMatch(name);
  if (match == null) return '';
  final number = match.group(1)!.replaceAll(',', '.');
  return '$number ${match.group(2)!.toUpperCase()}';
}

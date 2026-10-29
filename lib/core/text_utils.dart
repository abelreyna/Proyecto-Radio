const Map<String, String> _accents = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Pasa el texto a minúsculas y le quita las tildes para comparar sin
/// importar cómo lo escribió el usuario ("Áncash" == "ancash").
String normalizeText(String input) {
  final lower = input.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Compara dos textos ignorando mayúsculas y tildes, útil para ordenar
/// alfabéticamente nombres en español.
int compareNormalized(String a, String b) =>
    normalizeText(a).compareTo(normalizeText(b));

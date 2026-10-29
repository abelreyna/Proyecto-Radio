import '../core/station_classifier.dart';
import '../core/text_utils.dart';

/// Origen de una emisora dentro del catálogo híbrido.
enum StationSource { curated, radioBrowser }

/// Emisora de radio tal como la maneja la app.
///
/// Los nombres de los campos JSON siguen el formato de `radios_peru.json`
/// (`nombre`, `url_stream`, `es_destacada`...).
class Station {
  Station({
    required this.id,
    required this.nombre,
    required this.urlStream,
    this.frecuencia = '',
    this.region = '',
    this.genero = genreVariado,
    this.urlLogo = '',
    this.esDestacada = false,
    this.source = StationSource.curated,
  });

  /// Crea una emisora desde el catálogo curado (`radios_peru.json`).
  factory Station.fromJson(
    Map<String, dynamic> json, {
    StationSource source = StationSource.curated,
  }) {
    String read(String key) => (json[key] ?? '').toString().trim();
    final genero = read('genero');
    return Station(
      id: read('id'),
      nombre: read('nombre'),
      frecuencia: read('frecuencia'),
      region: read('region'),
      genero: genero.isEmpty ? genreVariado : genero,
      urlStream: read('url_stream'),
      urlLogo: read('url_logo'),
      esDestacada: json['es_destacada'] == true,
      source: source,
    );
  }

  /// Convierte un registro de Radio Browser API al modelo propio, deduciendo
  /// región, género y frecuencia a partir de sus datos libres.
  factory Station.fromRadioBrowser(Map<String, dynamic> json) {
    String read(String key) => (json[key] ?? '').toString().trim();
    final name = read('name');
    final resolved = read('url_resolved');
    return Station(
      id: 'rb_${read('stationuuid')}',
      nombre: name,
      frecuencia: extractFrequency(name),
      region: inferRegion(read('state')),
      genero: inferGenre(read('tags'), name),
      urlStream: resolved.isNotEmpty ? resolved : read('url'),
      urlLogo: read('favicon'),
      source: StationSource.radioBrowser,
    );
  }

  final String id;
  final String nombre;
  final String frecuencia;
  final String region;
  final String genero;
  final String urlStream;
  final String urlLogo;
  final bool esDestacada;
  final StationSource source;

  /// Texto normalizado sobre el que se aplica el buscador.
  late final String searchKey =
      normalizeText('$nombre $frecuencia $region $genero');

  /// Línea secundaria que se muestra bajo el nombre ("89.7 FM · Lima").
  String get subtitle =>
      [frecuencia, region].where((part) => part.isNotEmpty).join(' · ');

  /// Una emisora sin identificador, nombre o URL reproducible se descarta.
  bool get isValid =>
      id.isNotEmpty &&
      nombre.isNotEmpty &&
      (urlStream.startsWith('http://') || urlStream.startsWith('https://'));

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'frecuencia': frecuencia,
        'region': region,
        'genero': genero,
        'url_stream': urlStream,
        'url_logo': urlLogo,
        'es_destacada': esDestacada,
      };

  @override
  bool operator ==(Object other) => other is Station && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Station($id, $nombre)';
}

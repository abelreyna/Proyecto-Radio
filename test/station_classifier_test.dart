import 'package:flutter_test/flutter_test.dart';
import 'package:radios_peru_mix/core/station_classifier.dart';
import 'package:radios_peru_mix/core/text_utils.dart';

void main() {
  group('normalizeText', () {
    test('quita tildes y mayúsculas', () {
      expect(normalizeText('  ÁNCASH Ñuñoa '), 'ancash nunoa');
    });
  });

  group('inferRegion', () {
    test('reconoce departamentos con o sin tildes', () {
      expect(inferRegion('Lima'), 'Lima');
      expect(inferRegion('Junin'), 'Junín');
      expect(inferRegion('Apurimac'), 'Apurímac');
    });

    test('reconoce ciudades y provincias', () {
      expect(inferRegion('chimbote'), 'Áncash');
      expect(inferRegion('Trujillo'), 'La Libertad');
      expect(inferRegion('Huanta - Ayacucho'), 'Ayacucho');
      expect(inferRegion('Puno / Juliaca'), 'Puno');
      expect(inferRegion('Uchiza - San Martín'), 'San Martín');
      expect(inferRegion('Jumbilla,Gombora.Amazonas'), 'Amazonas');
    });

    test('no confunde "ica" dentro de otra palabra', () {
      expect(inferRegion('Música online'), '');
      expect(inferRegion('Ica'), 'Ica');
    });

    test('devuelve vacío si no reconoce la región', () {
      expect(inferRegion(''), '');
      expect(inferRegion('Online'), '');
    });
  });

  group('inferGenre', () {
    test('usa las etiquetas de Radio Browser', () {
      expect(inferGenre('news,noticias', 'Radio Exitosa'), 'Noticias');
      expect(inferGenre('sports', 'Ovación'), 'Deportes');
      expect(inferGenre('cumbia peruana,salsa', 'La Kalle'), 'Cumbia');
      expect(inferGenre('classic salsa', ''), 'Salsa');
      expect(inferGenre('andean,andino,folk', ''), 'Folklore');
      expect(inferGenre('latin,reggaeton,urban', ''), 'Urbano');
      expect(inferGenre('baladas pop', ''), 'Baladas');
      expect(inferGenre('classic rock,pop', ''), 'Rock & Pop');
    });

    test('devuelve Variado si no hay coincidencias', () {
      expect(inferGenre('', 'Radio Loreto'), genreVariado);
    });
  });

  group('extractFrequency', () {
    test('extrae FM y AM del nombre', () {
      expect(extractFrequency('Studio 92 (92.5 FM Lima)'), '92.5 FM');
      expect(extractFrequency('Radio Mágica 88,3 fm'), '88.3 FM');
      expect(extractFrequency('Ovación 620 AM'), '620 AM');
    });

    test('devuelve vacío si no hay frecuencia', () {
      expect(extractFrequency('Radio Nova'), '');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:radios_peru_mix/services/audio_handler.dart';

void main() {
  group('cleanIcyTitle', () {
    String? clean(String? raw) =>
        RadioAudioHandler.cleanIcyTitle(raw, 'Radio Oxígeno');

    test('conserva títulos reales de canciones o programas', () {
      expect(clean('Soda Stereo - De Música Ligera'), 'Soda Stereo - De Música Ligera');
      expect(clean('  Ampliación de Noticias  '), 'Ampliación de Noticias');
    });

    test('descarta códigos internos sin espacios', () {
      expect(clean('GRPP-OXIGENO'), isNull);
      expect(clean('stream_128k'), isNull);
    });

    test('descarta valores vacíos, genéricos o el nombre de la emisora', () {
      expect(clean(null), isNull);
      expect(clean('  '), isNull);
      expect(clean('-'), isNull);
      expect(clean('En vivo'), isNull);
      expect(clean('radio oxígeno'), isNull);
    });
  });
}

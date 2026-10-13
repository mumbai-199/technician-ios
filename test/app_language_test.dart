import 'package:flutter_test/flutter_test.dart';
import 'package:pest_control_app/services/app_language.dart';

void main() {
  group('AppText.translateForLocale', () {
    test('translates common screens and survey copy into Hindi', () {
      expect(AppText.translateForLocale('Survey Jobs', 'hi'), 'सर्वे के काम');
      expect(
        AppText.translateForLocale('Pending balance', 'hi'),
        'बाकी राशि',
      );
      expect(
        AppText.translateForLocale('Affected areas', 'hi'),
        'प्रभावित क्षेत्र',
      );
    });

    test('translates common screens and survey copy into Marathi', () {
      expect(
        AppText.translateForLocale('Survey Jobs', 'mr'),
        'सर्वेक्षणाची कामे',
      );
      expect(
        AppText.translateForLocale('Pending balance', 'mr'),
        'बाकी शिल्लक',
      );
      expect(
        AppText.translateForLocale('Affected areas', 'mr'),
        'प्रभावित भाग',
      );
    });

    test('translates before and after photo screen copy', () {
      for (final text in [
        'Before Service Photos',
        'After Service Photos',
        'Before & After Photos',
        'BEFORE SERVICE PHOTOS',
        'AFTER SERVICE PHOTOS',
        'No photos added yet',
        'Take Photo',
      ]) {
        expect(AppText.translateForLocale(text, 'hi'), isNot(text));
        expect(AppText.translateForLocale(text, 'mr'), isNot(text));
      }
      expect(AppText.translateForLocale('2 photos', 'hi'), '2 फ़ोटो');
      expect(AppText.translateForLocale('2 photos', 'mr'), '2 फोटो');
    });

    test('translates dynamic counts and labels without losing their values',
        () {
      expect(AppText.translateForLocale('4 trips', 'hi'), '4 यात्राएँ');
      expect(AppText.translateForLocale('4 trips', 'mr'), '4 फेऱ्या');
      expect(
        AppText.translateForLocale('Used (₹3/km)', 'mr'),
        'वापर (₹3/km)',
      );
      expect(
        AppText.translateForLocale('Showing 1 May to 31 May', 'hi'),
        'दिखा रहे हैं 1 May से 31 May',
      );
    });

    test('translates payment actions and dynamic payment summaries', () {
      expect(
        AppText.translateForLocale('CAPTURE PAYMENT PROOF', 'mr'),
        'पेमेंटचा पुरावा घ्या',
      );
      expect(
        AppText.translateForLocale('ADD ON SERVICE', 'mr'),
        'अतिरिक्त सेवा जोडा',
      );
      expect(
        AppText.translateForLocale('PAYMENT OPTION', 'hi'),
        'भुगतान विकल्प',
      );
      expect(
        AppText.translateForLocale('COMPLETE', 'mr'),
        'पूर्ण करा',
      );
      expect(
        AppText.translateForLocale('Payment Mode: CASH', 'mr'),
        'पेमेंट पद्धत: रोख',
      );
      expect(
        AppText.translateForLocale('Status: PENDING', 'mr'),
        'स्थिती: प्रलंबित',
      );
      expect(
        AppText.translateForLocale('Status: PAID', 'hi'),
        'स्थिति: भुगतान हो गया',
      );
    });

    test('translates dynamic screen labels and messages', () {
      expect(AppText.translateForLocale('Service 3', 'hi'), 'सेवा 3');
      expect(AppText.translateForLocale('Welcome Alex!', 'mr'), 'स्वागत आहे Alex!');
      expect(
        AppText.translateForLocale('Bag in completed successfully!', 'hi'),
        'बैग जमा सफलतापूर्वक हुआ!',
      );
      expect(
        AppText.translateForLocale('Chemical issued successfully!', 'mr'),
        'केमिकल यशस्वीरित्या वापरले!',
      );
      expect(
        AppText.translateForLocale('Date / Time: 10:30 AM', 'hi'),
        'तारीख / समय: 10:30 AM',
      );
      expect(
        AppText.translateForLocale('Start: 123 KM', 'mr'),
        'सुरुवात: 123 KM',
      );
      expect(
        AppText.translateForLocale('Error capturing image: camera denied', 'hi'),
        'छवि लेने में त्रुटि: camera denied',
      );
      expect(
        AppText.translateForLocale('Odometer Photo (Optional)', 'mr'),
        'ओडोमीटरचा फोटो (ऐच्छिक)',
      );
    });

    test('preserves English and leaves identifiers intact', () {
      expect(AppText.translateForLocale('Survey Jobs', 'en'), 'Survey Jobs');
      expect(AppText.translateForLocale('INTEGRITY', 'mr'), 'INTEGRITY');
    });
  });
}

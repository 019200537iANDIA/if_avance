import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:primeros_auxilios_app/services/guide_service.dart';
import 'package:primeros_auxilios_app/models/guide.dart';

void main() {
  late GuideService guideService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    guideService = GuideService();
  });

  group('GuideService Tests', () {
    test('createGuide agrega guía correctamente', () async {
      await guideService.createGuide(
        'Test Guide',
        'Test content with steps',
        'assets/images/test.png',
      );

      final snapshot = await fakeFirestore.collection('guides').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Test Guide');
    });

    test('getGuides retorna lista ordenada por título', () async {
      await guideService.createGuide('Zebra Guide', 'Content Z', 'path_z.png');
      await guideService.createGuide('Alpha Guide', 'Content A', 'path_a.png');
      await guideService.createGuide('Beta Guide', 'Content B', 'path_b.png');

      final stream = guideService.getGuides();
      final guides = await stream.first;

      expect(guides.length, 3);
      expect(guides[0].title, 'Alpha Guide');
      expect(guides[1].title, 'Beta Guide');
      expect(guides[2].title, 'Zebra Guide');
    });

    test('updateGuide actualiza campos correctamente', () async {
      final docRef = await fakeFirestore.collection('guides').add({
        'title': 'Original Title',
        'content': 'Original Content',
        'imagePath': 'original.png',
      });

      await guideService.updateGuide(
        docRef.id,
        'Updated Title',
        'Updated Content',
        'updated.png',
      );

      final updatedDoc = await fakeFirestore.collection('guides').doc(docRef.id).get();
      expect(updatedDoc.data()?['title'], 'Updated Title');
      expect(updatedDoc.data()?['content'], 'Updated Content');
    });

    test('deleteGuide elimina guía correctamente', () async {
      final docRef = await fakeFirestore.collection('guides').add({
        'title': 'Guide to Delete',
        'content': 'Content',
        'imagePath': 'path.png',
      });

      await guideService.deleteGuide(docRef.id);

      final deletedDoc = await fakeFirestore.collection('guides').doc(docRef.id).get();
      expect(deletedDoc.exists, isFalse);
    });

    test('initializeDefaultGuides carga 9 guías', () async {
      await guideService.initializeDefaultGuides();

      final snapshot = await fakeFirestore.collection('guides').get();
      expect(snapshot.docs.length, 9);
    });

    test('initializeDefaultGuides no duplica guías', () async {
      await guideService.initializeDefaultGuides();
      await guideService.initializeDefaultGuides();

      final snapshot = await fakeFirestore.collection('guides').get();
      expect(snapshot.docs.length, 9);
    });
  });
}
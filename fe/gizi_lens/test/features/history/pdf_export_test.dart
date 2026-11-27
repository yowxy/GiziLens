import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/services/pdf_report_service.dart';
import 'package:gizi_lens/core/services/user_session_service.dart';
import 'package:gizi_lens/features/history/views/history_detail_screen.dart';
import 'package:gizi_lens/features/history/views/widgets/audit_export_action_footer.dart';
import 'package:gizi_lens/features/history/views/widgets/pdf_export_success_dialog.dart';

Map<String, dynamic> _sampleInspection() => {
  'id': 'insp-001',
  'batchCode': 'MBG-2026-001',
  'schoolName': 'SDN Cibinong 01',
  'targetGroup': 'SD Kelas 4 – 6 (10 – 12 Tahun)',
  'session': 'Makan Pagi',
  'totalNetWeight': '330 gram',
  'scannedAt': '2026-11-23T09:00:00+07:00',
  'complianceStatus': 'SESUAI',
  'officerName': 'Nurul Anggraini, S.Gz',
  'components': [
    {
      'name': 'Nasi Putih',
      'gram': 120,
      'nutrition': {
        'calories': 156,
        'protein': 3.2,
        'fat': 0.4,
        'carbohydrate': 34.1,
        'fiber': 0.5,
      },
    },
    {
      'name': 'Ayam Goreng Serundeng',
      'gram': 60,
      'nutrition': {
        'calories': 165,
        'protein': 14.5,
        'fat': 10.2,
        'carbohydrate': 3.2,
        'fiber': 0.5,
      },
    },
    {
      'name': 'Tempe Goreng',
      'gram': 40,
      'nutrition': {
        'calories': 90,
        'protein': 7.5,
        'fat': 5.8,
        'carbohydrate': 3.6,
        'fiber': 1.4,
      },
    },
    {
      'name': 'Tumis Buncis Jagung',
      'gram': 45,
      'nutrition': {
        'calories': 35,
        'protein': 1.2,
        'fat': 1.5,
        'carbohydrate': 5.1,
        'fiber': 1.3,
      },
    },
    {
      'name': 'Anggur Merah',
      'gram': 65,
      'nutrition': {
        'calories': 45,
        'protein': 0.5,
        'fat': 0.1,
        'carbohydrate': 11.8,
        'fiber': 0.6,
      },
    },
  ],
  'nutrition': {
    'Kalori': {
      'currentValue': 491,
      'targetValue': 633.8,
      'unit': 'kkal',
      'percentageOfTarget': 77,
    },
    'Protein': {
      'currentValue': 26.9,
      'targetValue': 16.3,
      'unit': 'g',
      'percentageOfTarget': 166,
    },
    'Lemak': {
      'currentValue': 18.0,
      'targetValue': 21.1,
      'unit': 'g',
      'percentageOfTarget': 85,
    },
    'Karbohidrat': {
      'currentValue': 57.8,
      'targetValue': 94.3,
      'unit': 'g',
      'percentageOfTarget': 61,
    },
    'Serat': {
      'currentValue': 4.3,
      'targetValue': 8.9,
      'unit': 'g',
      'percentageOfTarget': 48,
    },
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportService', () {
    test('computeDataHash is deterministic and detects tampering', () {
      final item = _sampleInspection();
      final hash1 = PdfReportService.instance.computeDataHash(item);
      final hash2 = PdfReportService.instance.computeDataHash(item);

      expect(hash1, hasLength(64));
      expect(hash1, equals(hash2));

      final tampered = _sampleInspection();
      (tampered['components'] as List).first['gram'] = 999;
      final hashTampered = PdfReportService.instance.computeDataHash(tampered);
      expect(hashTampered, isNot(equals(hash1)));
    });

    test('generateReport produces valid PDF bytes with watermark and hashes', () async {
      final item = _sampleInspection();
      final result = await PdfReportService.instance.generateReport(item);

      expect(result.fileName, equals('Laporan_GiziLens_MBG-2026-001.pdf'));
      expect(result.dataHash, hasLength(64));
      expect(result.pdfHash, hasLength(64));
      expect(result.pdfBytes.length, greaterThan(1000));

      final header = ascii.decode(result.pdfBytes.take(5).toList());
      expect(header, equals('%PDF-'));
    });

    test('generateReport supports local scan nutrition keys', () async {
      final item = _sampleInspection()
        ..['nutrition'] = {
          'Energi Total': {
            'currentValue': 491,
            'targetValue': 633.8,
            'unit': 'kkal',
            'percentageOfTarget': 77,
          },
          'Protein Hewani & Nabati': {
            'currentValue': 26.9,
            'targetValue': 16.3,
            'unit': 'g',
            'percentageOfTarget': 166,
          },
          'Lemak Sehat': {
            'currentValue': 18.0,
            'targetValue': 21.1,
            'unit': 'g',
            'percentageOfTarget': 85,
          },
          'Karbohidrat Kompleks': {
            'currentValue': 57.8,
            'targetValue': 94.3,
            'unit': 'g',
            'percentageOfTarget': 61,
          },
          'Serat': {
            'currentValue': 4.3,
            'targetValue': 8.9,
            'unit': 'g',
            'percentageOfTarget': 48,
          },
        };

      final result = await PdfReportService.instance.generateReport(item);
      expect(result.pdfBytes.length, greaterThan(1000));
    });
  });

  group('HistoryDetailScreen Export PDF Flow', () {
    testWidgets('renders fixed action footer and shows popup dialog after export', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await UserSessionService.instance.upgradeSubscription(
        planName: 'GiziLens Premium',
      );
      addTearDown(UserSessionService.instance.reset);

      var exported = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryDetailScreen(
            item: _sampleInspection(),
            onExportPdf: (item) async {
              exported = true;
              final hash = PdfReportService.instance.computeDataHash(item);
              return PdfExportResult(
                pdfBytes: Uint8List.fromList(utf8.encode(hash)),
                fileName: 'Laporan_GiziLens_MBG-2026-001.pdf',
                dataHash: hash,
                pdfHash: hash,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuditExportActionFooter), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Kembali ke Riwayat'), findsOneWidget);

      await tester.tap(find.text('Export PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(exported, isTrue);
      expect(find.byType(PdfExportSuccessDialog), findsOneWidget);
      expect(find.text('PDF Berhasil dibuat!'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('#MBG-2026-001'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Kembali ke Beranda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PdfExportSuccessDialog), findsNothing);
    });

    testWidgets('free accounts are offered Premium instead of exporting', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        UserSessionService.instance.reset();
      });

      var exported = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryDetailScreen(
            item: _sampleInspection(),
            onExportPdf: (item) async {
              exported = true;
              final hash = PdfReportService.instance.computeDataHash(item);
              return PdfExportResult(
                pdfBytes: Uint8List.fromList(utf8.encode(hash)),
                fileName: 'Laporan_GiziLens_MBG-2026-001.pdf',
                dataHash: hash,
                pdfHash: hash,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(exported, isFalse);
      expect(find.text('Ekspor PDF khusus Premium'), findsOneWidget);
      expect(find.byType(PdfExportSuccessDialog), findsNothing);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_assets.dart';
import '../utils/wib_time.dart';

/// Result returned after generating and optionally saving/sharing an audit PDF.
class PdfExportResult {
  const PdfExportResult({
    required this.pdfBytes,
    required this.fileName,
    required this.dataHash,
    required this.pdfHash,
    this.savedFilePath,
  });

  final Uint8List pdfBytes;
  final String fileName;
  final String dataHash;
  final String pdfHash;
  final String? savedFilePath;
}

/// Service that builds GiziLens nutrition audit PDF reports matching the
/// official "Laporan GiziLens.docx" template with watermark and SHA-256 hashing.
class PdfReportService {
  PdfReportService._();
  static final PdfReportService instance = PdfReportService._();

  static const PdfColor _headerTeal = PdfColor.fromInt(0xFF1E5B4A);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF111827);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor _lightRowBg = PdfColor.fromInt(0xFFF6FAF8);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _hashBg = PdfColor.fromInt(0xFFF1F5F3);

  /// Computes a deterministic SHA-256 digest of the canonical inspection data.
  String computeDataHash(Map<String, dynamic> item) {
    final components = _mapList(item['components']).map((c) {
      final nut = _mapOrEmpty(c['nutrition']);
      return {
        'name': c['name']?.toString() ?? '',
        'gram': _toDouble(c['gram']),
        'calories': _toDouble(nut['calories']),
        'protein': _toDouble(nut['protein']),
        'fat': _toDouble(nut['fat']),
        'carbohydrate': _toDouble(nut['carbohydrate']),
        'fiber': _toDouble(nut['fiber']),
      };
    }).toList();

    final canonical = <String, dynamic>{
      'id': item['id']?.toString() ?? '',
      'batchCode': item['batchCode']?.toString() ?? '',
      'schoolName': item['schoolName']?.toString() ?? '',
      'targetGroup': item['targetGroup']?.toString() ?? '',
      'session': item['session']?.toString() ?? '',
      'totalNetWeight': item['totalNetWeight']?.toString() ?? '',
      'scannedAt': (item['scannedAt'] ?? item['createdDateIso'])?.toString() ?? '',
      'complianceStatus': item['complianceStatus']?.toString() ?? '',
      'officerName': (item['officerName'] ?? item['userEmail'])?.toString() ?? '',
      'components': components,
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(canonical)));
    return digest.toString();
  }

  /// Generates a PDF report matching `Laporan GiziLens.docx` and computes SHA-256 hashes.
  Future<PdfExportResult> generateReport(Map<String, dynamic> item) async {
    final batchCode = (item['batchCode'] as String?)?.trim().isNotEmpty == true
        ? item['batchCode'].toString().trim()
        : 'MBG-AUDIT';
    final dataHash = computeDataHash(item);
    final shortHash = dataHash.substring(0, 16).toUpperCase();

    final fonts = await _loadFonts();
    final logoImage = await _loadAssetImage(AppAssets.logoIcon);
    final watermarkImage = await _loadAssetImage(AppAssets.pdfWatermark);
    final trayPhoto = await _resolveTrayImage(item);

    final components = _mapList(item['components']);
    final scannedIso = (item['scannedAt'] ?? item['createdDateIso']) as String?;
    final instant = WibTime.parseInstant(scannedIso);
    final parsedDate = instant == null ? null : WibTime.calendar(instant);
    final dateText = _formatIndonesianDate(parsedDate);
    final timeText = _formatTimeWib(parsedDate);
    final targetGroup = item['targetGroup'] as String? ?? '-';
    final jenjang = _extractEducationLevel(targetGroup);
    final sessionLabel = _cleanSession(item['session'] as String?);
    final totalGram = _computeTotalGram(item, components);
    final totalCalories = _computeTotalCalories(components, item);
    final totalWeightText = _formatWeightLabel(item['totalNetWeight'], totalGram);
    final statusRaw = (item['complianceStatus'] as String? ?? 'SESUAI').toUpperCase();
    final statusText = statusRaw == 'TIDAK SESUAI' ? 'TIDAK SESUAI' : 'SESUAI';
    final officerName = _resolveOfficer(item);
    final akgRows = _buildAkgComparisonRows(item, components);

    final doc = pw.Document(
      title: 'Laporan Pemeriksaan GiziLens - $batchCode',
      author: 'Aplikasi GiziLens',
      subject: 'Laporan Hasil Pemeriksaan dan Analisis Gizi ($batchCode)',
      keywords: 'GiziLens, MBG, $batchCode, SHA256:$dataHash',
      creator: 'GiziLens Digital Audit System',
    );

    final baseStyle = pw.TextStyle(
      font: fonts.regular,
      fontBold: fonts.bold,
      fontSize: 9.5,
      color: _darkText,
      lineSpacing: 2.5,
    );

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 52),
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
      buildBackground: watermarkImage == null
          ? null
          : (context) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Opacity(
                  opacity: 0.9,
                  child: pw.Image(
                    watermarkImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColor.fromInt(0xFFD1D5DB), width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Dokumen digital GiziLens | ID Pemeriksaan: $batchCode | SHA-256: $shortHash',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 7.5,
                    color: _mutedText,
                  ),
                ),
              ),
              pw.Text(
                'Hal. ${context.pageNumber}/${context.pagesCount}',
                style: pw.TextStyle(
                  font: fonts.semiBold,
                  fontSize: 7.5,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Header Logo + Title
          pw.Center(
            child: pw.Column(
              children: [
                if (logoImage != null) ...[
                  pw.Image(logoImage, width: 36, height: 40),
                  pw.SizedBox(height: 6),
                ],
                pw.Text(
                  'GIZILENS',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: _headerTeal,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'LAPORAN HASIL PEMERIKSAAN DAN ANALISIS GIZI',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 13.5,
                    color: _darkText,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Sistem Penilaian Gizi Berbasis Digital',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 9,
                    color: _mutedText,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Dokumen ini memuat hasil identifikasi komponen makanan dan estimasi kandungan gizi berdasarkan pemindaian menggunakan aplikasi GiziLens.',
                  textAlign: pw.TextAlign.center,
                  style: baseStyle,
                ),
              ],
            ),
          ),

          if (trayPhoto != null) ...[
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFD1D5DB), width: 0.8),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    trayPhoto,
                    width: 240,
                    height: 165,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],

          pw.SizedBox(height: 14),
          _sectionHeader('IDENTITAS PEMERIKSAAN', fonts),
          pw.SizedBox(height: 6),
          _buildKeyValueTable(
            headers: const ['Keterangan', 'Data'],
            rows: [
              ['ID Pemeriksaan', batchCode],
              ['Tanggal Pemeriksaan', dateText],
              ['Waktu Pemeriksaan', timeText],
              ['Jenjang Pendidikan', jenjang],
              ['Sesi Makan', sessionLabel],
              ['Total Berat Makanan', totalWeightText],
              ['Status Pemeriksaan', statusText],
            ],
            fonts: fonts,
          ),

          pw.SizedBox(height: 14),
          _sectionHeader('A. HASIL IDENTIFIKASI KOMPONEN MAKANAN', fonts),
          pw.SizedBox(height: 4),
          pw.Text(
            'Berdasarkan hasil pemindaian menggunakan sistem GiziLens, diperoleh ${_countWordsId(components.length)} komponen makanan yang teridentifikasi dalam satu porsi makanan.',
            style: baseStyle,
          ),
          pw.SizedBox(height: 6),
          _buildDataTable(
            headers: const ['No.', 'Komponen Makanan', 'Berat', 'Energi'],
            columnWidths: const {
              0: pw.FixedColumnWidth(32),
              1: pw.FlexColumnWidth(3.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.3),
            },
            alignments: const [
              pw.Alignment.center,
              pw.Alignment.centerLeft,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
            ],
            rows: [
              for (var i = 0; i < components.length; i++)
                [
                  '${i + 1}',
                  components[i]['name']?.toString() ?? '-',
                  '${_formatIdNumber(_toDouble(components[i]['gram']))} g',
                  '${_formatIdNumber(_toDouble(_mapOrEmpty(components[i]['nutrition'])['calories']))} kkal',
                ],
              [
                '',
                'TOTAL',
                '${_formatIdNumber(totalGram)} g',
                '${_formatIdNumber(totalCalories)} kkal',
              ],
            ],
            boldLastRow: true,
            fonts: fonts,
          ),

          pw.SizedBox(height: 14),
          _sectionHeader('B. RINCIAN KANDUNGAN GIZI', fonts),
          pw.SizedBox(height: 4),
          pw.Text(
            'Berikut merupakan estimasi kandungan zat gizi dari masing-masing komponen makanan berdasarkan hasil analisis sistem.',
            style: baseStyle,
          ),
          pw.SizedBox(height: 6),
          _buildDataTable(
            headers: const [
              'Komponen Makanan',
              'Protein',
              'Lemak',
              'Karbohidrat',
              'Serat',
            ],
            columnWidths: const {
              0: pw.FlexColumnWidth(2.6),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(1.1),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.1),
            },
            alignments: const [
              pw.Alignment.centerLeft,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
            ],
            rows: [
              for (final component in components)
                [
                  component['name']?.toString() ?? '-',
                  '${_formatIdNumber(_toDouble(_mapOrEmpty(component['nutrition'])['protein']))} g',
                  '${_formatIdNumber(_toDouble(_mapOrEmpty(component['nutrition'])['fat']))} g',
                  '${_formatIdNumber(_toDouble(_mapOrEmpty(component['nutrition'])['carbohydrate']))} g',
                  '${_formatIdNumber(_toDouble(_mapOrEmpty(component['nutrition'])['fiber']))} g',
                ],
            ],
            fonts: fonts,
          ),

          pw.SizedBox(height: 14),
          _sectionHeader('C. ANALISIS KECUKUPAN GIZI TERHADAP TARGET AKG', fonts),
          pw.SizedBox(height: 4),
          pw.Text(
            'Hasil analisis kandungan gizi dibandingkan dengan target kebutuhan gizi yang digunakan oleh sistem GiziLens berdasarkan kelompok sasaran penerima MBG.',
            style: baseStyle,
          ),
          pw.SizedBox(height: 6),
          _buildDataTable(
            headers: const ['Parameter Gizi', 'Hasil', 'Target', 'Persentase'],
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.1),
            },
            alignments: const [
              pw.Alignment.centerLeft,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
              pw.Alignment.centerRight,
            ],
            rows: akgRows
                .map((row) => [row.label, row.actualText, row.targetText, row.percentText])
                .toList(),
            fonts: fonts,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Catatan: Nilai target dan persentase pada tabel mengikuti data yang ditampilkan pada hasil pemindaian GiziLens.',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8.5,
              color: _mutedText,
            ),
          ),

          pw.SizedBox(height: 14),
          _sectionHeader('D. KESIMPULAN HASIL PEMERIKSAAN', fonts),
          pw.SizedBox(height: 4),
          ..._buildConclusionParagraphs(
            batchCode: batchCode,
            statusText: statusText,
            akgRows: akgRows,
            style: baseStyle,
          ),

          pw.SizedBox(height: 14),
          _sectionHeader('E. INFORMASI DAN VALIDASI DOKUMEN', fonts),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dokumen ini dihasilkan secara digital melalui aplikasi GiziLens berdasarkan data hasil pemindaian dan analisis sistem.',
            style: baseStyle,
          ),
          pw.SizedBox(height: 6),
          _buildKeyValueTable(
            headers: const ['Keterangan', 'Data'],
            rows: [
              ['ID Dokumen', batchCode],
              ['Sumber Data', 'Aplikasi GiziLens'],
              ['Status Dokumen', 'Hasil Pemeriksaan Digital'],
              if (officerName != '-') ['Petugas Verifikator', officerName],
              ['Hash Integritas (SHA-256)', dataHash],
            ],
            highlightLastValueMonospace: true,
            fonts: fonts,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: _hashBg,
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFC7D7D0), width: 0.6),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Verifikasi Keaslian Digital (SHA-256): $dataHash',
              style: pw.TextStyle(
                font: fonts.semiBold,
                fontSize: 7.5,
                color: _headerTeal,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Dokumen ini merupakan hasil analisis digital dan bukan pengganti verifikasi ahli gizi atau pemeriksaan laboratorium.',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8.5,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );

    final pdfBytes = await doc.save();
    final pdfHash = sha256.convert(pdfBytes).toString();
    final safeCode = batchCode.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final fileName = 'Laporan_GiziLens_$safeCode.pdf';

    return PdfExportResult(
      pdfBytes: pdfBytes,
      fileName: fileName,
      dataHash: dataHash,
      pdfHash: pdfHash,
    );
  }

  /// Generates, saves locally when possible, and triggers the OS PDF share/save sheet.
  Future<PdfExportResult> exportAndShareReport(
    Map<String, dynamic> item, {
    bool openShareSheet = true,
  }) async {
    final result = await generateReport(item);
    String? savedPath;

    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}${result.fileName}');
        await file.writeAsBytes(result.pdfBytes, flush: true);
        savedPath = file.path;
      } catch (e) {
        debugPrint('PDF local file write skipped: $e');
      }
    }

    if (openShareSheet) {
      try {
        await Printing.sharePdf(
          bytes: result.pdfBytes,
          filename: result.fileName,
        );
      } catch (e) {
        debugPrint('PDF share sheet skipped: $e');
      }
    }

    return PdfExportResult(
      pdfBytes: result.pdfBytes,
      fileName: result.fileName,
      dataHash: result.dataHash,
      pdfHash: result.pdfHash,
      savedFilePath: savedPath,
    );
  }

  pw.Widget _sectionHeader(String title, _PdfFonts fonts) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: fonts.bold,
        fontSize: 10.5,
        color: _headerTeal,
      ),
    );
  }

  pw.Widget _buildKeyValueTable({
    required List<String> headers,
    required List<List<String>> rows,
    required _PdfFonts fonts,
    bool highlightLastValueMonospace = false,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(2.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerTeal),
          children: headers
              .map(
                (header) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 8.5,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? const pw.BoxDecoration(color: _lightRowBg) : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                child: pw.Text(
                  rows[i][0],
                  style: pw.TextStyle(font: fonts.semiBold, fontSize: 8.5, color: _darkText),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                child: pw.Text(
                  rows[i][1],
                  style: pw.TextStyle(
                    font: (highlightLastValueMonospace && i == rows.length - 1)
                        ? fonts.regular
                        : fonts.regular,
                    fontSize: (highlightLastValueMonospace && i == rows.length - 1)
                        ? 7.2
                        : 8.5,
                    color: _darkText,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildDataTable({
    required List<String> headers,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required List<pw.Alignment> alignments,
    required List<List<String>> rows,
    required _PdfFonts fonts,
    bool boldLastRow = false,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.6),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerTeal),
          children: [
            for (var col = 0; col < headers.length; col++)
              pw.Container(
                alignment: alignments[col],
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(
                  headers[col],
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8.5,
                    color: PdfColors.white,
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: (boldLastRow && r == rows.length - 1)
                ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE9F2EE))
                : (r.isOdd ? const pw.BoxDecoration(color: _lightRowBg) : null),
            children: [
              for (var col = 0; col < rows[r].length; col++)
                pw.Container(
                  alignment: alignments[col],
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
                  child: pw.Text(
                    rows[r][col],
                    style: pw.TextStyle(
                      font: (boldLastRow && r == rows.length - 1)
                          ? fonts.bold
                          : fonts.regular,
                      fontSize: 8.5,
                      color: _darkText,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  List<pw.Widget> _buildConclusionParagraphs({
    required String batchCode,
    required String statusText,
    required List<_AkgRow> akgRows,
    required pw.TextStyle style,
  }) {
    final below = akgRows.where((r) => r.percent < 90).toList();
    final metOrAbove = akgRows.where((r) => r.percent >= 90).toList();

    final secondParagraph = StringBuffer();
    if (below.isEmpty && metOrAbove.isNotEmpty) {
      secondParagraph.write(
        'Hasil perbandingan menunjukkan bahwa seluruh parameter gizi utama telah memenuhi rentang target yang ditetapkan oleh sistem GiziLens.',
      );
    } else if (metOrAbove.isNotEmpty) {
      final top = metOrAbove.reduce((a, b) => a.percent >= b.percent ? a : b);
      secondParagraph.write(
        'Hasil perbandingan menunjukkan bahwa beberapa parameter gizi belum mencapai target yang ditetapkan, sementara parameter ${top.label.toLowerCase()} telah mencapai ${top.percentText} dari target sistem.',
      );
    } else {
      secondParagraph.write(
        'Hasil perbandingan menunjukkan bahwa sebagian besar parameter gizi masih memerlukan penyesuaian porsi terhadap target sistem.',
      );
    }

    return [
      pw.Text(
        'Berdasarkan hasil pemindaian dan analisis kandungan gizi, porsi makanan dengan ID pemeriksaan $batchCode memperoleh status $statusText berdasarkan indikator penilaian yang digunakan oleh sistem GiziLens.',
        style: style,
      ),
      pw.SizedBox(height: 5),
      pw.Text(secondParagraph.toString(), style: style),
      pw.SizedBox(height: 5),
      pw.Text(
        'Hasil pemeriksaan ini dapat digunakan sebagai bahan evaluasi dan pertimbangan bagi petugas SPPG dalam melakukan pemantauan kesesuaian komposisi dan kecukupan gizi makanan yang disalurkan kepada penerima manfaat MBG.',
        style: style,
      ),
    ];
  }

  Future<_PdfFonts> _loadFonts() async {
    try {
      final regData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      final semiData = await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf');
      final boldData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
      return _PdfFonts(
        regular: pw.Font.ttf(regData),
        semiBold: pw.Font.ttf(semiData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (_) {
      return _PdfFonts(
        regular: pw.Font.helvetica(),
        semiBold: pw.Font.helveticaBold(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }

  Future<pw.MemoryImage?> _loadAssetImage(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.MemoryImage?> _resolveTrayImage(Map<String, dynamic> item) async {
    final rawBytes = item['imageBytes'];
    if (rawBytes is Uint8List && rawBytes.isNotEmpty) {
      return pw.MemoryImage(rawBytes);
    }
    final b64 = item['imageBase64'] as String?;
    if (b64 != null && b64.trim().isNotEmpty) {
      try {
        final payload = b64.contains(',') ? b64.split(',').last : b64;
        return pw.MemoryImage(base64Decode(payload));
      } catch (_) {}
    }
    final imageUrl = item['imageUrl'] as String?;
    if (imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.bodyBytes.isNotEmpty) {
          return pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }
    return null;
  }

  static List<_AkgRow> _buildAkgComparisonRows(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> components,
  ) {
    final nutrition = _mapOrEmpty(item['nutrition']);
    final targetSnapshot = _mapOrEmpty(item['targetAkg2019']);

    const specs = [
      (
        label: 'Serat',
        keys: ['Serat'],
        compKey: 'fiber',
        targetKey: 'fiber',
        unit: 'g',
      ),
      (
        label: 'Energi Total',
        keys: ['Kalori', 'Energi Total'],
        compKey: 'calories',
        targetKey: 'calories',
        unit: 'kkal',
      ),
      (
        label: 'Karbohidrat Kompleks',
        keys: ['Karbohidrat', 'Karbohidrat Kompleks'],
        compKey: 'carbohydrate',
        targetKey: 'carbohydrate',
        unit: 'g',
      ),
      (
        label: 'Lemak Sehat',
        keys: ['Lemak', 'Lemak Sehat'],
        compKey: 'fat',
        targetKey: 'fat',
        unit: 'g',
      ),
      (
        label: 'Protein Hewani & Nabati',
        keys: ['Protein', 'Protein Hewani & Nabati'],
        compKey: 'protein',
        targetKey: 'protein',
        unit: 'g',
      ),
    ];

    return specs.map((spec) {
      Map<String, dynamic> metric = const {};
      for (final k in spec.keys) {
        if (nutrition[k] is Map) {
          metric = Map<String, dynamic>.from(nutrition[k] as Map);
          break;
        }
      }

      var current = _toDouble(metric['currentValue']);
      if (current == 0 && components.isNotEmpty) {
        current = components.fold<double>(
          0,
          (sum, c) => sum + _toDouble(_mapOrEmpty(c['nutrition'])[spec.compKey]),
        );
      }

      var target = _toDouble(metric['targetValue']);
      if (target == 0) {
        target = _toDouble(targetSnapshot[spec.targetKey]);
      }

      final unit = (metric['unit']?.toString().isNotEmpty == true)
          ? metric['unit'].toString()
          : spec.unit;
      final rawPct = _toDouble(metric['percentageOfTarget']);
      final pct = rawPct > 0
          ? rawPct.round()
          : (target > 0 ? (current / target * 100).round() : 0);

      return _AkgRow(
        label: spec.label,
        actualText: '${_formatIdNumber(current)} $unit',
        targetText: target > 0 ? '${_formatIdNumber(target)} $unit' : '-',
        percent: pct,
        percentText: target > 0 || rawPct > 0 ? '$pct%' : '-',
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static double _computeTotalGram(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> components,
  ) {
    final sum = components.fold<double>(0, (acc, c) => acc + _toDouble(c['gram']));
    if (sum > 0) return sum;
    final rawWeight = item['totalNetWeight']?.toString() ?? '';
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(rawWeight);
    if (match != null) {
      return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  static double _computeTotalCalories(
    List<Map<String, dynamic>> components,
    Map<String, dynamic> item,
  ) {
    final sum = components.fold<double>(
      0,
      (acc, c) => acc + _toDouble(_mapOrEmpty(c['nutrition'])['calories']),
    );
    if (sum > 0) return sum;
    final nut = _mapOrEmpty(item['nutrition']);
    final cal = _mapOrEmpty(nut['Kalori'] ?? nut['Energi Total']);
    return _toDouble(cal['currentValue']);
  }

  static String _formatWeightLabel(dynamic rawWeight, double totalGram) {
    final text = rawWeight?.toString().trim() ?? '';
    if (text.isNotEmpty && text != '-') return text;
    if (totalGram > 0) return '${_formatIdNumber(totalGram)} gram';
    return '-';
  }

  static String _extractEducationLevel(String targetGroup) {
    final upper = targetGroup.toUpperCase();
    if (upper.contains('SMA') || upper.contains('SMK')) return targetGroup;
    if (upper.contains('SMP')) return targetGroup;
    if (upper.contains('SD')) return targetGroup;
    return targetGroup.trim().isEmpty ? '-' : targetGroup;
  }

  static String _cleanSession(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == '-') return 'Makan Siang';
    return value;
  }

  static String _resolveOfficer(Map<String, dynamic> item) {
    final name = item['officerName']?.toString().trim() ?? '';
    if (name.isNotEmpty && name != '-') return name;
    final email = item['userEmail']?.toString().trim() ?? '';
    if (email.isNotEmpty && email != '-') return email;
    return '-';
  }

  static String _formatIndonesianDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTimeWib(DateTime? date) {
    if (date == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.hour)}.${two(date.minute)} WIB';
  }

  static String _formatIdNumber(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _countWordsId(int count) {
    const words = {
      0: 'nol',
      1: 'satu',
      2: 'dua',
      3: 'tiga',
      4: 'empat',
      5: 'lima',
      6: 'enam',
      7: 'tujuh',
      8: 'delapan',
      9: 'sembilan',
      10: 'sepuluh',
    };
    return words[count] ?? '$count';
  }
}

class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.semiBold,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font semiBold;
  final pw.Font bold;
}

class _AkgRow {
  const _AkgRow({
    required this.label,
    required this.actualText,
    required this.targetText,
    required this.percent,
    required this.percentText,
  });

  final String label;
  final String actualText;
  final String targetText;
  final int percent;
  final String percentText;
}

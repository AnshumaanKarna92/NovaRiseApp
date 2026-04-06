import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nova_rise_app/core/models/lesson_record.dart';
import 'package:nova_rise_app/core/models/school_class.dart';

class DiaryPdfGenerator {
  static Future<void> generateAndPrint({
    required List<LessonRecord> records,
    required SchoolClass schoolClass,
    required DateTime date,
  }) async {
    final font = await PdfGoogleFonts.notoSansBengaliRegular();
    final fontBold = await PdfGoogleFonts.notoSansBengaliBold();

    final pdf = pw.Document();

    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final dateStr = DateFormat("dd.MM.yy").format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        height: 50,
                        width: 50,
                        child: pw.Image(logoImage),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "NOVA RISE ACADEMY",
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 22,
                              color: PdfColor.fromHex("#003D5B"),
                            ),
                          ),
                          pw.Text(
                            "Daily Academic Diary",
                            style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Date: $dateStr", style: pw.TextStyle(font: fontBold, fontSize: 13)),
                      pw.Text("Class: ${schoolClass.name}", style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),  // Period
                  1: const pw.FixedColumnWidth(70),  // Subject
                  2: const pw.FixedColumnWidth(60),  // Chapter
                  3: const pw.FlexColumnWidth(3),    // Teaching Learning Activity
                  4: const pw.FlexColumnWidth(2),    // Home Work
                  5: const pw.FixedColumnWidth(60),  // Sign.
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex("#F3F4F6")),
                    children: [
                      _buildHeaderCell("Period", fontBold),
                      _buildHeaderCell("Subject", fontBold),
                      _buildHeaderCell("Chapter", fontBold),
                      _buildHeaderCell("Teaching Learning Activity", fontBold),
                      _buildHeaderCell("Home Work", fontBold),
                      _buildHeaderCell("Sign.", fontBold),
                    ],
                  ),
                  // Table Rows
                  ...records.map((r) => pw.TableRow(
                    children: [
                      _buildCell(r.period, font),
                      _buildCell(r.subject, font),
                      _buildCell(r.chapter, font),
                      _buildCell(r.topicBn.isNotEmpty ? "${r.topic}\n${r.topicBn}" : r.topic, font),
                      _buildCell(r.homeworkBn.isNotEmpty ? "${r.homework}\n${r.homeworkBn}" : r.homework, font),
                      _buildCell("${r.teacherName}\n${DateFormat("dd/MM/yy").format(r.createdAt)}", font, fontSize: 8),
                    ],
                  )),
                  // Fill empty rows if less than 8
                  for (var i = records.length; i < 8; i++)
                    pw.TableRow(
                      children: [
                        _buildCell("${i + 1}${_getOrdinal(i + 1)}", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                      ],
                    ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 1)),
                    ),
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(records.isNotEmpty ? records.first.teacherName : "Class Teacher", style: pw.TextStyle(font: font, fontSize: 9)),
                          pw.Text("Class Teacher Signature", style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateAndShare({
    required List<LessonRecord> records,
    required SchoolClass schoolClass,
    required DateTime date,
  }) async {
    final font = await PdfGoogleFonts.notoSansBengaliRegular();
    final fontBold = await PdfGoogleFonts.notoSansBengaliBold();

    final pdf = pw.Document();

    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final dateStr = DateFormat("dd.MM.yy").format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        height: 50,
                        width: 50,
                        child: pw.Image(logoImage),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "NOVA RISE ACADEMY",
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 22,
                              color: PdfColor.fromHex("#003D5B"),
                            ),
                          ),
                          pw.Text(
                            "Daily Academic Diary",
                            style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Date: $dateStr", style: pw.TextStyle(font: fontBold, fontSize: 13)),
                      pw.Text("Class: ${schoolClass.name}", style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),  // Period
                  1: const pw.FixedColumnWidth(70),  // Subject
                  2: const pw.FixedColumnWidth(60),  // Chapter
                  3: const pw.FlexColumnWidth(3),    // Teaching Learning Activity
                  4: const pw.FlexColumnWidth(2),    // Home Work
                  5: const pw.FixedColumnWidth(60),  // Sign.
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex("#F3F4F6")),
                    children: [
                      _buildHeaderCell("Period", fontBold),
                      _buildHeaderCell("Subject", fontBold),
                      _buildHeaderCell("Chapter", fontBold),
                      _buildHeaderCell("Teaching Learning Activity", fontBold),
                      _buildHeaderCell("Home Work", fontBold),
                      _buildHeaderCell("Sign.", fontBold),
                    ],
                  ),
                  // Table Rows
                  ...records.map((r) => pw.TableRow(
                    children: [
                      _buildCell(r.period, font),
                      _buildCell(r.subject, font),
                      _buildCell(r.chapter, font),
                      _buildCell(r.topicBn.isNotEmpty ? "${r.topic}\n${r.topicBn}" : r.topic, font),
                      _buildCell(r.homeworkBn.isNotEmpty ? "${r.homework}\n${r.homeworkBn}" : r.homework, font),
                      _buildCell("${r.teacherName}\n${DateFormat("dd/MM/yy").format(r.createdAt)}", font, fontSize: 8),
                    ],
                  )),
                  // Fill empty rows if less than 8
                  for (var i = records.length; i < 8; i++)
                    pw.TableRow(
                      children: [
                        _buildCell("${i + 1}${_getOrdinal(i + 1)}", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                        _buildCell("", font),
                      ],
                    ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 1)),
                    ),
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(records.isNotEmpty ? records.first.teacherName : "Class Teacher", style: pw.TextStyle(font: font, fontSize: 9)),
                          pw.Text("Class Teacher Signature", style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(
      bytes: pdfBytes, 
      filename: 'Diary_${schoolClass.name}_${DateFormat("dd-MM-yy").format(date)}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      ),
    );
  }

  static pw.Widget _buildCell(String text, pw.Font font, {double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize),
      ),
    );
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return "th";
    switch (n % 10) {
      case 1: return "st";
      case 2: return "nd";
      case 3: return "rd";
      default: return "th";
    }
  }
}

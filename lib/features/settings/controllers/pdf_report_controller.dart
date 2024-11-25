import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:stiuffcoletorinventario/core/models/inventory_item.dart';
import 'package:stiuffcoletorinventario/core/models/package_model.dart';
import 'package:stiuffcoletorinventario/core/providers/inventory_provider.dart';

extension MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var index = 0;
    for (var element in this) {
      yield f(index, element);
      index++;
    }
  }
}

class PdfReportController extends ChangeNotifier {
  Future<void> openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      debugPrint('Erro ao abrir o arquivo PDF.');
    }
  }

  List<InventoryItem> getFilteredByDateRange(
      List<InventoryItem> items, String selectedDateRange) {
    List<InventoryItem> filteredItems = List.from(items);

    switch (selectedDateRange) {
      case "allRecentHistory":
        filteredItems = items
            .where((item) => item.date
                .isAfter(DateTime.now().subtract(const Duration(days: 365))))
            .toList();
        break;

      case "last7Days":
        filteredItems = items.where((item) {
          final now = DateTime.now();
          return item.date.isAfter(now.subtract(const Duration(days: 7))) &&
              item.date.isBefore(now.add(const Duration(days: 1)));
        }).toList();
        break;

      case "last15Days":
        filteredItems = items.where((item) {
          final now = DateTime.now();
          return item.date.isAfter(now.subtract(const Duration(days: 15))) &&
              item.date.isBefore(now.add(const Duration(days: 1)));
        }).toList();
        break;

      case "last30Days":
        filteredItems = items.where((item) {
          final now = DateTime.now();
          return item.date.isAfter(now.subtract(const Duration(days: 30))) &&
              item.date.isBefore(now.add(const Duration(days: 1)));
        }).toList();
        break;

      default:
        debugPrint("Error. Invalid date range selected.");
        filteredItems = [];
        break;
    }

    return filteredItems;
  }

  pw.Align getPackageHeader(PackageModel package) {
    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: package.name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          package.tags.isNotEmpty && package.tags.first != ""
              ? pw.Text(
                  'Tags: "${package.tags.join('"; "')}".',
                  style: const pw.TextStyle(fontSize: 12),
                )
              : pw.Text(
                  'Tags: Nenhuma tag associada.',
                  style: pw.TextStyle(
                      fontSize: 12, fontStyle: pw.FontStyle.italic),
                ),
        ],
      ),
    );
  }

  pw.Align getItemHeader(InventoryItem item, int index) {
    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$index. ${item.name} ',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.TextSpan(
                  text: '(#${item.barcode})',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Paragraph(
            text: item.description ?? "N/A",
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  pw.Table fillAndGetTable(InventoryItem item) {
    final parts = (item.geolocation ?? 'N/A').split(',');
    String? latitude;
    String? longitude;
    String? altitude;

    if (parts.length >= 3) {
      latitude = parts[0].split(':')[1].trim();
      longitude = parts[1].split(':')[1].trim();
      altitude = parts[2].split(':')[1].trim();
    }

    final table = getTableSkeleton(
      nestedTableData: [
        [
          'Data de Captura:',
          (DateFormat('dd/MM/yyyy HH:mm').format(item.date))
        ],
        [
          'Localização:',
          item.location,
        ],
        ['Cell 5', 'Cell 6'],
        [
          'Latitude:',
          latitude ?? 'N/A',
        ],
        [
          'Longitude:',
          longitude ?? 'N/A',
        ],
        [
          'Altitude:',
          altitude ?? 'N/A',
        ],
        ['Cell 13', 'Cell 14'],
        ['Cell 15', 'Cell 16'],
      ],
      mergedCellData: [
        'Coordenadas',
        'Observações',
        item.observations ?? 'N/A',
      ],
      imageTableData: [
        [
          item.images != null && item.images!.isNotEmpty
              ? item.images![0]
              : 'N/A',
          item.images != null && item.images!.length > 1
              ? item.images![1]
              : 'N/A'
        ],
        [
          item.images != null && item.images!.length > 2
              ? item.images![2]
              : 'N/A',
          item.images != null && item.images!.length > 3
              ? item.images![3]
              : 'N/A'
        ],
      ],
    );
    return table;
  }

  pw.Table getTableSkeleton({
    required List<List<String>> nestedTableData,
    required List<String> mergedCellData,
    required List<List<String>> imageTableData,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Table(
              border: pw.TableBorder.all(),
              children: List.generate(8, (rowIndex) {
                return pw.TableRow(
                  children: List.generate(1, (colIndex) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Table(
                        border: pw.TableBorder.all(),
                        children: List.generate(1, (innerRowIndex) {
                          if (rowIndex == 2 || rowIndex == 6 || rowIndex == 7) {
                            return pw.TableRow(
                              children: List.generate(1, (innerColIndex) {
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Container(
                                    constraints: const pw.BoxConstraints(
                                      maxWidth: 200,
                                    ),
                                    child: pw.Text(
                                      mergedCellData[rowIndex == 2
                                          ? 0
                                          : rowIndex == 6
                                              ? 1
                                              : 2],
                                      softWrap: true,
                                      textAlign: pw.TextAlign.justify,
                                    ),
                                  ),
                                );
                              }),
                            );
                          }
                          return pw.TableRow(
                            children: List.generate(2, (innerColIndex) {
                              return pw.SizedBox(
                                width: 110,
                                child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    nestedTableData[rowIndex][innerColIndex],
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    );
                  }),
                );
              }),
            ),
            pw.Column(
              children: [
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              'Imagens do Item',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: List.generate(2, (rowIndex) {
                    return pw.TableRow(
                      children: List.generate(2, (colIndex) {
                        final imagePath = imageTableData[rowIndex][colIndex];
                        if (imagePath.isNotEmpty &&
                            File(imagePath).existsSync()) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.SizedBox(
                              height: 100,
                              width: 80,
                              child: pw.Center(
                                child: pw.Image(
                                  pw.MemoryImage(
                                    File(imagePath).readAsBytesSync(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.SizedBox(
                              height: 100,
                              width: 100,
                              child: pw.Center(
                                child: pw.Text('N/A'),
                              ),
                            ),
                          );
                        }
                      }),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<List<PackageModel>> _showPackageSelectionDialog(
      BuildContext context,
      List<PackageModel> packages,
      List<PackageModel> previouslySelectedPackages) async {
    List<PackageModel> selectedPackages = List.from(previouslySelectedPackages);
    Completer<List<PackageModel>> completer = Completer();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Escolha um pacote',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final package = packages[index];
                          return CheckboxListTile(
                            title: Text(
                              package.name,
                              style: const TextStyle(color: Colors.black),
                            ),
                            value: selectedPackages.contains(package),
                            activeColor: Colors.blue,
                            onChanged: (isSelected) {
                              setState(() {
                                if (isSelected == true) {
                                  selectedPackages.add(package);
                                } else {
                                  selectedPackages.remove(package);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete(previouslySelectedPackages);
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete(selectedPackages);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return completer.future;
  }

  Future<File?> generatePdf(
    BuildContext context,
    String selectedOption,
    String selectedDateRange,
  ) async {
    final pdf = pw.Document();
    final inventoryProvider =
        Provider.of<InventoryProvider>(context, listen: false);

    List<PackageModel> packages = inventoryProvider.packages;
    List<InventoryItem> items = inventoryProvider.items;

    items = getFilteredByDateRange(items, selectedDateRange);

    /// 0 - All Packages (Geração c/ todos pacotes e seus respectivos itens)
    /// 1 - Items Only (Todos itens, sem pacotes)
    /// 2 - Selected Packages Only (Apenas os pacotes selecionados e seus respectivos itens)
    late int reportGenerationMode;
    List<PackageModel> selectedPackages = [];
    switch (selectedOption) {
      case "allPackages":
        reportGenerationMode = 0;
        break;
      case "allItems":
        reportGenerationMode = 1;
        break;
      case "selectPackages":
        reportGenerationMode = 2;
        selectedPackages = await _showPackageSelectionDialog(
            context, packages, selectedPackages);
        break;
      default:
        debugPrint("Error. Invalid generation mode selected.");
        break;
    }

    // Operation is canceled
    if (reportGenerationMode == 2 && selectedPackages.isEmpty) {
      return null;
    } else if (reportGenerationMode == 2) {
      packages = packages
          .where((package) => selectedPackages.contains(package))
          .toList();
    }

    pdf.addPage(pw.MultiPage(
      build: (pw.Context context) {
        int globalItemCounter = 0;

        return [
          pw.Center(
            child: pw.Text(
              'Relatório de Inventário Local',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 20),
          ...packages.mapIndexed((packageIndex, package) {
            final packageItems =
                items.where((item) => item.packageId == package.id).toList();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (reportGenerationMode == 0 || reportGenerationMode == 2)
                  getPackageHeader(package),
                pw.SizedBox(height: 20),
                ...packageItems.mapIndexed((index, item) {
                  globalItemCounter++;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      (reportGenerationMode == 0 || reportGenerationMode == 2)
                          ? getItemHeader(item, index + 1)
                          : getItemHeader(item, globalItemCounter),
                      fillAndGetTable(item),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }),
                if (packageItems.isEmpty)
                  (reportGenerationMode == 0 || reportGenerationMode == 2)
                      ? pw.Text(
                          'Nenhum item encontrado neste pacote.',
                          style: pw.TextStyle(
                              fontSize: 12, fontStyle: pw.FontStyle.italic),
                        )
                      : pw.SizedBox.shrink(),
                pw.SizedBox(height: 40),
              ],
            );
          }),
        ];
      },
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_inventario.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}

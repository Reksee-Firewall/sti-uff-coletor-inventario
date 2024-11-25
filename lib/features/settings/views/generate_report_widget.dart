// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stiuffcoletorinventario/features/settings/controllers/pdf_report_controller.dart';
import 'package:stiuffcoletorinventario/shared/utils/app_colors.dart';
import 'package:open_file/open_file.dart';

class GenerateReportWidget extends StatefulWidget {
  const GenerateReportWidget({super.key});

  @override
  GenerateReportWidgetState createState() => GenerateReportWidgetState();
}

class GenerateReportWidgetState extends State<GenerateReportWidget> {
  String? selectedOption = 'allPackages';
  String? selectedDateRange = 'allRecentHistory';
  final PdfReportController _pdfReportController = PdfReportController();

  Future<void> _generatePdf(BuildContext context) async {
    final file = await _pdfReportController.generatePdf(
        context, selectedOption!, selectedDateRange!);
    _showOpenPdfDialog(context, file);
  }

  void _showOpenPdfDialog(BuildContext context, File? file) {
    (file != null)
        ? showDialog(
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
                        'Relatório Gerado',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Clique em 'Visualizar' para abrir o relatório no leitor de PDF instalado em seu dispositivo.",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.black54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
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
                              _openPdf(file);
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
                              'Visualizar',
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
          )
        : null;
  }

  Future<void> _openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      debugPrint('Erro ao abrir o arquivo PDF.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
          child: Text(
            "Relatórios",
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Gere um breve relatório em PDF com as principais informações do inventário local.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackgroundColor,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quais informações você gostaria de incluir no relatório?",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Incluir todos os pacotes capturados',
                      style: TextStyle(fontSize: 14)),
                  value: 'allPackages',
                  groupValue: selectedOption,
                  onChanged: (String? value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                RadioListTile<String>(
                  title: const Text('Incluir todos os itens capturados',
                      style: TextStyle(fontSize: 14)),
                  value: 'allItems',
                  groupValue: selectedOption,
                  onChanged: (String? value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                RadioListTile<String>(
                  title: const Text('Selecionar pacotes a serem incluídos',
                      style: TextStyle(fontSize: 14)),
                  value: 'selectPackages',
                  groupValue: selectedOption,
                  onChanged: (String? value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      "Opções de filtragem por período",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      RadioListTile<String>(
                        title: const Text('Todo o histórico disponível',
                            style: TextStyle(fontSize: 14)),
                        value: 'allRecentHistory',
                        groupValue: selectedDateRange,
                        onChanged: (String? value) {
                          setState(() {
                            selectedDateRange = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      RadioListTile<String>(
                        title: const Text('Apenas os itens dos últimos 7 dias',
                            style: TextStyle(fontSize: 14)),
                        value: 'last7Days',
                        groupValue: selectedDateRange,
                        onChanged: (String? value) {
                          setState(() {
                            selectedDateRange = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      RadioListTile<String>(
                        title: const Text('Apenas os itens dos últimos 15 dias',
                            style: TextStyle(fontSize: 14)),
                        value: 'last15Days',
                        groupValue: selectedDateRange,
                        onChanged: (String? value) {
                          setState(() {
                            selectedDateRange = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      RadioListTile<String>(
                        title: const Text('Apenas os itens dos últimos 30 dias',
                            style: TextStyle(fontSize: 14)),
                        value: 'last30Days',
                        groupValue: selectedDateRange,
                        onChanged: (String? value) {
                          setState(() {
                            selectedDateRange = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _generatePdf(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBackgroundColor,
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      elevation: 1,
                      shadowColor: AppColors.primaryColor.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: BorderSide(
                            color: AppColors.primaryColor.withOpacity(0.5),
                            width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Gerar Relatório',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

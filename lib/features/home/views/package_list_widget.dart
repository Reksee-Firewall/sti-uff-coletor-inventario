import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stiuffcoletorinventario/core/models/inventory_item.dart';
import 'package:stiuffcoletorinventario/core/models/package_model.dart';
import 'package:stiuffcoletorinventario/core/providers/inventory_provider.dart';
import 'package:stiuffcoletorinventario/shared/utils/app_colors.dart';
import 'package:intl/intl.dart';

class PackageListWidget extends StatefulWidget {
  const PackageListWidget({super.key});

  @override
  State<PackageListWidget> createState() => _PackageListWidgetState();
}

class _PackageListWidgetState extends State<PackageListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      await provider.updatePackagesItemsMap();
    });
  }

  void _showItemDetails(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Código de Barras: ${item.barcode}'),
                Text('Data de Captura: ${item.date}'),
                Text('Descrição: ${item.description ?? "Não disponível"}'),
                Text('Observações: ${item.observations ?? "Não disponível"}'),
                Text('Localização: ${item.location}'),
                Text('Geolocalização: ${item.geolocation ?? "Não disponível"}'),
                if (item.images != null && item.images!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Imagens:'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: item.images!.map((imageUrl) {
                      return Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  List<PackageModel> _sortPackagesByCreatedAt(List<PackageModel> packages) {
    final sortedPackages = List<PackageModel>.from(packages);

    for (int i = 1; i < sortedPackages.length; i++) {
      final current = sortedPackages[i];
      int j = i - 1;

      while (j >= 0 &&
          (sortedPackages[j]
                  .createdAt
                  ?.isBefore(current.createdAt ?? DateTime.now()) ??
              false)) {
        sortedPackages[j + 1] = sortedPackages[j];
        j--;
      }
      sortedPackages[j + 1] = current;
    }

    return sortedPackages;
  }

  Map<String, List<PackageModel>> _groupPackagesByMonth(
      List<PackageModel> packages) {
    final Map<String, List<PackageModel>> groupedPackages = {};
    for (var package in packages) {
      final date = package.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final monthYear = DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(date);
      groupedPackages.putIfAbsent(monthYear, () => []).add(package);
    }
    return groupedPackages;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final packages = inventoryProvider.sentPackages;
        final packagesItemsMap = inventoryProvider.packagesItemsMap;

        // IssueFix: Sort() turns the items of the first package invisible. Do NOT use it.
        // packages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

        if (packages.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum pacote encontrado.",
              style: TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
          );
        }

        final sortedPackages = _sortPackagesByCreatedAt(packages);
        final groupedPackages = _groupPackagesByMonth(sortedPackages);

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, left: 16.0, bottom: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pacotes Enviados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.shadowColor,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedPackages.keys.length,
              itemBuilder: (context, index) {
                final monthYear = groupedPackages.keys.elementAt(index);
                final monthPackages = groupedPackages[monthYear]!;

                return ExpansionTile(
                  title: Text(
                    monthYear,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: monthPackages.map((PackageModel package) {
                    final items = packagesItemsMap[package.id] ?? [];
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(
                        package.createdAt ??
                            DateTime.fromMillisecondsSinceEpoch(0));

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: ExpansionTile(
                        title:
                            Text("Pacote: ${package.name} (ID: ${package.id})"),
                        subtitle: Text(
                            "Tags: ${package.tags.join(', ')}\nEnviado em: $formattedDate"),
                        children: items.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Nenhum item associado a este pacote.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ]
                            : items.map((item) {
                                return ListTile(
                                  title: Text(item.name),
                                  subtitle:
                                      Text("Código de Barras: ${item.barcode}"),
                                  leading: const Icon(Icons.inventory),
                                  onTap: () => _showItemDetails(context, item),
                                );
                              }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
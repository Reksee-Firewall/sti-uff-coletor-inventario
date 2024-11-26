// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stiuffcoletorinventario/core/models/inventory_item.dart';
import 'package:stiuffcoletorinventario/core/models/package_model.dart';
import 'package:stiuffcoletorinventario/core/providers/inventory_provider.dart';
import 'package:stiuffcoletorinventario/features/home/controllers/tag_filter_controller.dart';
import 'package:stiuffcoletorinventario/shared/utils/app_colors.dart';
import 'package:intl/intl.dart';

class PackageListWidget extends StatefulWidget {
  const PackageListWidget({super.key});

  @override
  State<PackageListWidget> createState() => _PackageListWidgetState();
}

class _PackageListWidgetState extends State<PackageListWidget> {
  String _searchQuery = '';
  bool _isLoading = false;

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
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailColumn('Código de Barras', item.barcode),
                  _buildDetailColumn('Data de Captura',
                      DateFormat('dd/MM/yyyy HH:mm').format(item.date)),
                  _buildDetailColumn(
                      'Descrição', item.description ?? 'Não disponível'),
                  _buildDetailColumn(
                      'Observações', item.observations ?? 'Não disponível'),
                  _buildDetailColumn('Localização', item.location),
                  _buildGeolocation(item.geolocation ?? 'Não disponível'),
                  if (item.images != null && item.images!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Imagens:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.images!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.images![index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeolocation(String geolocation) {
    if (geolocation.isEmpty) {
      return const Text('Geolocalização: Não disponível');
    }

    final parts = geolocation.split(',');
    if (parts.length < 3) return const Text('Geolocalização: Não disponível');

    final latitude = parts[0].split(':')[1].trim();
    final longitude = parts[1].split(':')[1].trim();
    final altitude = parts[2].split(':')[1].trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Geolocalização:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Latitude: $latitude',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          'Longitude: $longitude',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          'Altitude: $altitude',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  void _showFilterModal(BuildContext context, List<String> allTags) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<TagFilterController>(
          builder: (context, tagFilterController, child) {
            return AlertDialog(
              title: const Center(
                child: Text(
                  'Filtrar por Tags',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: allTags.where((tag) => tag.isNotEmpty).map((tag) {
                    return FilterChip(
                      backgroundColor: Colors.white,
                      selectedColor: const Color.fromARGB(255, 92, 181, 255),
                      label: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      selected: tagFilterController.isTagSelected(tag),
                      onSelected: (isSelected) {
                        tagFilterController.toggleTag(tag);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, TagFilterController>(
      builder: (context, inventoryProvider, tagFilterController, child) {
        final provider = Provider.of<InventoryProvider>(context, listen: false);

        final packages = inventoryProvider.sentPackages;
        final packagesItemsMap = inventoryProvider.packagesItemsMap;

        final filteredPackages = packages.where((package) {
          final matchesPackageName =
              package.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesItemName = packagesItemsMap[package.id]?.any((item) {
                return item.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
              }) ??
              false;

          final matchesTags = tagFilterController.selectedTags.isEmpty ||
              package.tags
                  .any((tag) => tagFilterController.selectedTags.contains(tag));

          return (matchesPackageName || matchesItemName) && matchesTags;
        }).toList();

        final sortedPackages = _sortPackagesByCreatedAt(filteredPackages);
        final groupedPackages = _groupPackagesByMonth(sortedPackages);

        final allTags =
            packages.expand((package) => package.tags).toSet().toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16.0, bottom: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pacotes Enviados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.shadowColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 2.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                ),
                              )
                            : const Icon(Icons.replay_sharp),
                        label: const Text('Recarregar Aba'),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  await provider.updatePackagesItemsMap();
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.amber,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 16.0, top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(5.0),
                              ),
                            ),
                            child: TextField(
                              onChanged: (query) {
                                setState(() {
                                  _searchQuery = query;
                                });
                              },
                              textAlign: TextAlign.start,
                              decoration: const InputDecoration(
                                hintText: 'Pesquisar Pacote ou Item',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12.0),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list),
                              color: Colors.white,
                              onPressed: () {
                                _showFilterModal(context, allTags);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filteredPackages.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          "Nenhum pacote encontrado! =(",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  (filteredPackages.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupedPackages.keys.length,
                            itemBuilder: (context, index) {
                              final monthYear =
                                  groupedPackages.keys.elementAt(index);
                              final monthPackages = groupedPackages[monthYear]!;

                              return Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                  // splashColor: Colors.white,
                                ),
                                child: ExpansionTile(
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 215, 97),
                                  tilePadding: const EdgeInsets.only(
                                    left: 20,
                                    bottom: 8.0,
                                    right: 20.0,
                                  ),
                                  title: Text(
                                    toBeginningOfSentenceCase(monthYear) ??
                                        monthYear,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 22,
                                    ),
                                  ),
                                  children:
                                      monthPackages.map((PackageModel package) {
                                    final items =
                                        packagesItemsMap[package.id] ?? [];
                                    final formattedDate = DateFormat(
                                            'dd/MM/yyyy HH:mm')
                                        .format(package.createdAt ??
                                            DateTime.fromMillisecondsSinceEpoch(
                                                0));

                                    return Column(
                                      children: [
                                        Card(
                                          margin: const EdgeInsets.only(
                                              bottom: 8.0,
                                              left: 16.0,
                                              right: 16.0),
                                          child: ExpansionTile(
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  package.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                ),
                                                Text(
                                                  "ID: ${package.id}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: Text(
                                                "Tags: ${package.tags.join(', ')}\nEnviado em: $formattedDate",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.grey[500],
                                                      fontSize: 14,
                                                    ),
                                              ),
                                            ),
                                            children: items.isEmpty
                                                ? [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: Text(
                                                        "Nenhum item associado a este pacote.",
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                : items.map((item) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4.0),
                                                      child: ListTile(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    16.0),
                                                        title: Text(
                                                          item.name,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          "Código de Barras: ${item.barcode}",
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        leading: Icon(
                                                          Icons.all_inbox,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                        onTap: () =>
                                                            _showItemDetails(
                                                                context, item),
                                                      ),
                                                    );
                                                  }).toList(),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 8.0,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

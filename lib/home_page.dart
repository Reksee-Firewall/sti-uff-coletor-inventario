import 'package:flutter/material.dart';
import 'package:stiuffcoletorinventario/app_colors.dart';
import 'package:stiuffcoletorinventario/app_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stiuffcoletorinventario/info_carousel.dart';
import 'package:stiuffcoletorinventario/inventory_grid.dart';
import 'package:stiuffcoletorinventario/package_filter_dialog.dart';
import 'package:stiuffcoletorinventario/package_list.dart';
import 'package:stiuffcoletorinventario/package_search_bar.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = HomeController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      drawer: const AppDrawer(selectedIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const InfoCarousel(),
            const SizedBox(height: 20),
            const InventoryGrid(),
            const SizedBox(height: 20),
            _buildPackageSection(),
            const SizedBox(height: 85),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Leitor de Barras",
        backgroundColor: AppColors.appBarColor,
        splashColor: AppColors.lightOrangeSplashColor,
        onPressed: () => {},
        child: SvgPicture.asset(
          'assets/icons/barcode.svg',
          width: 36,
          height: 36,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPackageSection() {
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
        Container(
          decoration: const BoxDecoration(
            color: Colors.amber,
          ),
          child: Column(
            children: [
              PackageSearchBar(
                searchController: controller.searchController,
                onFilterPressed: () => _showTagFilterDialog(),
              ),
              if (controller.selectedTags.isNotEmpty) _buildSelectedTags(),
              PackageList(groupedPackages: controller.filteredPackages),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTags() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.selectedTags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      controller.selectedTags.remove(tag);
                      controller.filterPackages();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showTagFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return PackageFilterDialog(
          allTags: controller.getAllTags(),
          selectedTags: controller.selectedTags,
        );
      },
    );
    if (result != null) {
      setState(() {
        controller.selectedTags = result;
      });
      controller.filterPackages();
    }
  }
}

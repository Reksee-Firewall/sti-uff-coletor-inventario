import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stiuffcoletorinventario/features/camera/views/barcode_scanner_camera_page.dart';
import 'package:stiuffcoletorinventario/features/camera/views/ml_kit_camera_page.dart';
import 'package:stiuffcoletorinventario/features/camera/views/mobile_scanner_camera_page.dart';
import 'package:stiuffcoletorinventario/features/home/views/package_list_widget.dart';
import 'package:stiuffcoletorinventario/shared/utils/app_colors.dart';
import 'package:stiuffcoletorinventario/shared/components/app_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stiuffcoletorinventario/shared/components/info_carousel.dart';
import 'package:stiuffcoletorinventario/features/home/views/inventory_grid.dart';
import 'package:stiuffcoletorinventario/shared/utils/custom_page_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? selectedFABOption;

  @override
  void initState() {
    super.initState();
    _loadFABOption();
  }

  _loadFABOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFABOption = prefs.getString('fabOption') ?? 'barcode';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      drawer: AppDrawer(selectedIndex: 0),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          children: const [
            InfoCarousel(),
            SizedBox(height: 20),
            InventoryGrid(),
            SizedBox(height: 20),
            PackageListWidget(),
            SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: _getFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _getFloatingActionButton() {
    switch (selectedFABOption) {
      case 'lowEndScanner':
        return FloatingActionButton(
          tooltip: "Leitor de Barras Low-End",
          backgroundColor: Colors.green,
          splashColor: AppColors.lightOrangeSplashColor,
          onPressed: () => Navigator.push(
            context,
            CustomPageRoute(page: const AlternateCameraPage()),
          ),
          child: SvgPicture.asset(
            'assets/icons/barcode.svg',
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        );
      case 'mlKitScanner':
        return const BarcodeScannerWidget();
      case 'barcode':
      default:
        return FloatingActionButton(
          tooltip: "Leitor de Barras",
          backgroundColor: Colors.red,
          splashColor: AppColors.lightOrangeSplashColor,
          onPressed: () => Navigator.push(
            context,
            CustomPageRoute(page: const CameraPage()),
          ),
          child: SvgPicture.asset(
            'assets/icons/barcode.svg',
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        );
    }
  }
}

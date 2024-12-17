import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stiuffcoletorinventario/features/settings/views/generate_report_widget.dart';
import 'package:stiuffcoletorinventario/shared/components/app_drawer.dart';
import 'package:stiuffcoletorinventario/features/settings/views/package_widget.dart';
import 'package:stiuffcoletorinventario/shared/utils/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String? selectedFABOption;

  @override
  void initState() {
    super.initState();
    _loadFABOption();
  }

  _loadFABOption() async {
    final prefs = await SharedPreferences.getInstance();
    String? loadedOption = prefs.getString('fabOption');
    setState(() {
      selectedFABOption = loadedOption ?? 'barcode';
    });
    debugPrint("Modo de Captura carregado: $selectedFABOption");
  }

  _saveFABOption(String option) async {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setString('fabOption', option);
    if (success) {
      debugPrint("Modo de Captura salvo: $option");
    } else {
      debugPrint("Falha ao salvar o Modo de Captura.");
    }
  }

  Widget _buildCaptureOptions() {
    final Map<String, String> captureModes = {
      'barcode': 'Leitor de Alta Performance',
      'lowEndScanner': 'Leitor de Baixa Performance',
      'mlKitScanner': 'Leitor de Imagens Estáticas',
    };

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
            child: Text(
              "Modo de Captura",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Ajuste caso o dispositivo tenha baixa performance na captura em tempo real.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: selectedFABOption,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  border: InputBorder.none,
                ),
                items: captureModes.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(captureModes[value] ?? value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedFABOption = newValue;
                    _saveFABOption(newValue!);
                    debugPrint("Modo de Captura salvo.");
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Talvez seja necessário reiniciar a aplicação para que as alterações surtam efeito.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: AppDrawer(selectedIndex: 1),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCaptureOptions(),
                const GenerateReportWidget(),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                const PackageWidget(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

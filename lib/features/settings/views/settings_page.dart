import 'package:flutter/material.dart';
import 'package:stiuffcoletorinventario/features/settings/views/generate_report_widget.dart';
import 'package:stiuffcoletorinventario/shared/components/app_drawer.dart';
import 'package:stiuffcoletorinventario/features/settings/views/package_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
        child: const Padding(
          padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenerateReportWidget(),
                SizedBox(height: 30),
                Divider(),
                SizedBox(height: 20),
                PackageWidget(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

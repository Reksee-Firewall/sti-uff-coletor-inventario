// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:stiuffcoletorinventario/features/login/controller/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Text(
                  'Carregando...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void debugClaims() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult();
      debugPrint('Claims do usuário: ${idTokenResult.claims}');
    }
  }

  Future<void> _loginWithGoogle() async {
    _showLoadingDialog();
    final user = await _authController.signInWithGoogle();

    if (user == null) {
      Navigator.pop(context);
    }

    if (user != null) {
      // IssueFix: Aguarda a propagação dos claims. (Tempo para garantir que as claims foram definidas no backend)
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      // Renovando o token do usuário para garantir que as claims sejam atualizadas
      final idTokenResult = await FirebaseAuth.instance.currentUser!
          .getIdTokenResult(true); // true força a atualização do token

      debugClaims();

      final isAllowed = idTokenResult.claims?['allowed'] == true;

      if (isAllowed) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Acesso negado!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: 'Foi feita uma tentativa de login com ',
                    ),
                    TextSpan(
                      text: '"${user.email}"',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: '. No entanto, apenas os emails de domínio ',
                    ),
                    const TextSpan(
                      text: '"id.uff.br"',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: ' são autorizados a utilizar esta aplicação.',
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _switchAccount() async {
    await _authController.signOut();
    await _loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/RenderColetorUFF.svg',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Coletor Inventário',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Leitura rápida e precisa dos códigos de inventário!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _loginWithGoogle,
              icon: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Image.asset(
                  'assets/icons/google.png',
                  width: 20,
                  height: 20,
                ),
              ),
              label: const Text('Entrar com Google'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _switchAccount,
              child: const Text(
                'Trocar conta',
                style: TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

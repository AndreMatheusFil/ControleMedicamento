import 'package:controlemedicamento/ui/home_dashboard_page.dart';
import 'package:controlemedicamento/ui/prescription_ai_page.dart';
import 'package:flutter/material.dart';
import 'home_horario_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeDashboardPage(),
    HomePageCadastroState(),
    PrescriptionAiPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: "Cadastro",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "IA",
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'home_horario_page.dart'; // importa sua tela

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Páginas que serão exibidas
  final List<Widget> _pages = [
    Center(child: Text("Página Inicial")),
    HomePageCadastroState(),
    Center(child: Text("IA")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Exemplo BottomNavigationBar")),
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

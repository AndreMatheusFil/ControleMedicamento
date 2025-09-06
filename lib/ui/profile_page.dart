import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil"),
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
        toolbarHeight: 75.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar e informações básicas
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Usuário",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Controle de Medicamentos",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Configurações
            Card(
              child: Column(
                children: [
                  _buildSettingsItem(
                    Icons.notifications,
                    "Notificações",
                    "Gerenciar lembretes e alertas",
                    () {
                      _showNotificationSettings();
                    },
                  ),
                  Divider(height: 1),
                  _buildSettingsItem(
                    Icons.backup,
                    "Backup",
                    "Fazer backup dos seus dados",
                    () {
                      _showBackupDialog();
                    },
                  ),
                  Divider(height: 1),
                  _buildSettingsItem(
                    Icons.restore,
                    "Restaurar",
                    "Restaurar dados do backup",
                    () {
                      _showRestoreDialog();
                    },
                  ),
                  Divider(height: 1),
                  _buildSettingsItem(
                    Icons.help,
                    "Ajuda",
                    "Central de ajuda e suporte",
                    () {
                      _showHelpDialog();
                    },
                  ),
                  Divider(height: 1),
                  _buildSettingsItem(
                    Icons.info,
                    "Sobre",
                    "Informações do aplicativo",
                    () {
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Estatísticas
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Estatísticas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Dias", "0", Icons.calendar_today),
                        _buildStatItem("Medicamentos", "0", Icons.medication),
                        _buildStatItem("Lembretes", "0", Icons.alarm),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Botão de logout/reset
            Card(
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  "Resetar Aplicativo",
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text("Limpar todos os dados"),
                onTap: () {
                  _showResetDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Configurações de Notificação"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text("Lembretes de medicamentos"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Notificações sonoras"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Vibração"),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Backup"),
        content: Text("Funcionalidade de backup será implementada em breve."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Restaurar"),
        content: Text("Funcionalidade de restauração será implementada em breve."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ajuda"),
        content: Text("Para suporte, entre em contato através do email: suporte@controlemedicamento.com"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sobre o App"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Controle de Medicamentos"),
            Text("Versão: 1.0.0"),
            SizedBox(height: 10),
            Text("Um aplicativo para ajudar você a controlar seus medicamentos e horários de forma eficiente."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Resetar Aplicativo"),
        content: Text("Tem certeza que deseja resetar o aplicativo? Todos os dados serão perdidos permanentemente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Funcionalidade de reset será implementada em breve."),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text("Resetar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

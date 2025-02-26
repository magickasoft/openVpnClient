import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => VpnState(),
        child: MaterialApp(home: HomeScreen()),
      ),
    );

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OpenVPN _openVpn = OpenVPN();
  bool _isInitialized = false;
  VpnStatus _vpnStatus = VpnStatus.empty();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

   Future<void> _initialize() async {
    await _openVpn.initialize(
      lastStatus: (status) => setState(() => _vpnStatus = status),
    );
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('VPN App')),
      body: Center(
        child: !_isInitialized
            ? CircularProgressIndicator()
            : Consumer<VpnState>(
                builder: (context, state, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusText(state.status),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _toggleVpn(state),
                      child: Text(state.isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusText(VpnStatus status) {
    return Text(
      status.toString().split('.').last,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _toggleVpn(VpnState state) async {
    print('_toggleVpn');

    if (state.isConnected) {
      _openVpn.disconnect();
    } else {
      _startVpn();
    }
  }

  Future<void> _startVpn() async {
    bool isConnected = await _checkPermissions();

    if (!await _checkPermissions()) return;

    String config = await rootBundle.loadString('assets/config.ovpn');

    await _openVpn.connect(
      config,
      'open_vpn',
      username: 'vpn',
      password: 'vpn',
      // onConnectionStatusChanged: (status) {
      //   print('Connection Status: $status');
      // },
    );
  }

  Future<bool> _checkPermissions() async {
    bool location = await Permission.location.request().isGranted;

    print('location $location');

    if (location) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _openVpn.disconnect();
    super.dispose();
  }
}


class VpnState with ChangeNotifier {
  VpnStatus _status = VpnStatus.empty();
  bool _isConnected = false;

  VpnStatus get status => _status;
  bool get isConnected => _isConnected;

  // Метод для обновления статуса
  void updateStatus(VpnStatus status) {
    _status = status;
    _isConnected = status.connectedOn != null; // Проверка на подключение
    notifyListeners();
  }
}
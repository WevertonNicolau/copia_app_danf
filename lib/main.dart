import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String server = 'super-author.cloudmqtt.com';
  final int port = 1883;
  final String username = 'tdmstjgu';
  final String password = 'mBv2M7HusSx8';
  String publishTopic = '/Danf/WN/V3/Mqtt/Comando';
  String subscribeTopic = '/Danf/WN/V3/Mqtt/Feedback';

  MqttServerClient? client;
  bool _connected = false;
  Timer? _timer;
  bool _isReconnecting = false; // Flag para controle de reconexão

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _timer?.cancel();
    client?.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    client = MqttServerClient(server, '');
    client!.port = port;
    client!.logging(on: true);
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .authenticateAs(username, password)
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      await client!.connect(username, password);
    } catch (e) {
      print('Exception: $e');
      client!.disconnect();
      _reconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      setState(() {
        _connected = true;
      });
      _isReconnecting = false; // Reset flag
      _startSendingMessages();
    } else {
      print(
          'ERROR: MQTT client connection failed - disconnecting, state is ${client!.connectionStatus!.state}');
      client!.disconnect();
      _reconnect();
    }

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');
    });

    _subscribeToTopic(subscribeTopic);
  }

  void _reconnect() {
    if (!_isReconnecting) {
      _isReconnecting =
          true; // Set flag to true to prevent multiple reconnections
      Future.delayed(Duration(seconds: 1), () {
        if (!_connected) {
          _connect();
        }
      }).whenComplete(
          () => _isReconnecting = false); // Reset flag after reconnect attempt
    }
  }

  void _subscribeToTopic(String topic) {
    client!.subscribe(topic, MqttQos.atMostOnce);
  }

  void _startSendingMessages() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _publish('SA');
    });
  }

  void _onConnected() {
    print('Connected');
  }

  void _onDisconnected() {
    print('Disconnected');
    setState(() {
      _connected = false;
    });
    _reconnect();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  Future<void> _publish(String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    try {
      client!
          .publishMessage(publishTopic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e) {
      print('Exceção ao publicar mensagem: $e');
      _showConnectionError();
    }
  }

  void _showConnectionError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erro de Conexão'),
          content: Text('Houve um problema ao conectar-se ao servidor MQTT.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Retorna falso para impedir o fechamento do aplicativo
        return false;
      },
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen(client: client!),
        routes: {
          '/home': (context) => HomeScreen(client: client!),
          '/ambientes': (context) => AmbientesScreen(),
          '/sala': (context) => SalaScreen(),
          '/cozinha': (context) => CozinhaScreen(),
          '/suite_master': (context) => SuiteMasterScreen(),
          '/sala_lamp': (context) => SalaLampScreen(
              client: client!,
              publishTopic: publishTopic,
              subscribeTopic: subscribeTopic),
          '/cozinha_lamp': (context) => CozinhaLampScreen(),
          '/suite_master_lamp': (context) => SuiteMasterLampScreen(),
          '/sala_ice': (context) => SalaIceScreen(),
          '/cozinha_ice': (context) => CozinhaIceScreen(),
          '/suite_master_ice': (context) => SuiteMasterIceScreen(),
          '/sala_window': (context) => SalaWindowScreen(),
          '/cozinha_window': (context) => CozinhaWindowScreen(),
          '/suite_master_window': (context) => SuiteMasterWindowScreen(),
          '/cenas': (context) => CenasScreen(
              client: client!,
              publishTopic: publishTopic,
              subscribeTopic: subscribeTopic),
        },
      ),
    );
  }
}

class BackgroundScaffold extends StatelessWidget {
  final Widget child;

  const BackgroundScaffold({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
              'assets/images/background.jpg'), // Altere para o caminho da sua imagem
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final MqttClient client;

  HomeScreen({required this.client});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  bool _isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    _checkMqttConnection(); // Checa a conexão inicial
    // Inicia o Timer para atualizar o status a cada 1 segundo
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      _checkMqttConnection(); // Atualiza o status de conexão
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancela o Timer quando o widget é removido
    super.dispose();
  }

  void _checkMqttConnection() {
    // Verifica o status de conexão do cliente MQTT
    bool isConnected =
        widget.client.connectionStatus?.state == MqttConnectionState.connected;

    setState(() {
      _isMqttConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Container para o background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/background.jpg'), // Substitua pelo caminho da sua imagem
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo/logo.png', // Caminho da imagem do logo
                    width: 400, // Largura da imagem
                    height: 100, // Altura da imagem
                  ),
                  SizedBox(height: 20), // Espaço entre a imagem e o botão
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ambientes');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color.fromARGB(255, 200, 200, 200), // Cor de fundo
                    ),
                    child: Text(
                      'Entrar',
                      style:
                          TextStyle(color: Colors.black), // Cor do texto preta
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'status: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white), // Cor do texto branca
                  ),
                  Icon(
                    Icons.circle,
                    color: _isMqttConnected ? Colors.green : Colors.red,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CenasScreen extends StatelessWidget {
  final MqttClient client;
  final String publishTopic;
  final String subscribeTopic;

  CenasScreen({
    required this.client,
    required this.publishTopic,
    required this.subscribeTopic,
  });

  void sendMqttMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    client.publishMessage(publishTopic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, '/ambientes', (route) => false);
        return false;
      },
      child: Scaffold(
        endDrawer: Drawer(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            color: Colors.black.withOpacity(0.9),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: Text(
                    'Ambientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Sala', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/sala_lamp');
                  },
                ),
                ListTile(
                  title: Text('Suíte Master',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/suite_master_lamp');
                  },
                ),
                ListTile(
                  title: Text('Cozinha', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cozinha_lamp');
                  },
                ),
                Divider(color: Colors.white),
                ListTile(
                  title: Text('Cenas', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cenas');
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Container para o background
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // AppBar personalizado
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text(
                  'Cenas',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/ambientes', (route) => false);
                  },
                ),
                actions: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Conteúdo da tela
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 80),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildActionControl('Ligar tudo', 'OFAN'),
                        buildActionControl('Apagar tudo', 'OFAO'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionControl(String label, String mqttMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          ElevatedButton(
            onPressed: () {
              sendMqttMessage(mqttMessage);
            },
            child: Text('Executar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 56, 103, 141),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AmbientesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Container para o background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/background.jpg'), // Substitua pelo caminho da sua imagem
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                title: Text('Ambientes', style: TextStyle(color: Colors.white)),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(
                    color: Colors.white), // Define a cor dos ícones para branco
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home', // Nome da rota para a HomeScreen
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmbienteCard(
                        title: 'Sala',
                        lampRoute: '/sala_lamp',
                        iceRoute: '/sala_ice',
                        windowRoute: '/sala_window',
                      ),
                      AmbienteCard(
                        title: 'Cozinha',
                        lampRoute: '/cozinha_lamp',
                        iceRoute: '/cozinha_ice',
                        windowRoute: '/cozinha_window',
                      ),
                      AmbienteCard(
                        title: 'Suíte Master',
                        lampRoute: '/suite_master_lamp',
                        iceRoute: '/suite_master_ice',
                        windowRoute: '/suite_master_window',
                      ),
                      // Adicione mais abas conforme necessário
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Container(
          width: MediaQuery.of(context).size.width *
              0.5, // Define o menu para abrir até o meio da página
          color: Colors.black.withOpacity(0.9), // Define o fundo preto
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.8), // Fundo preto para o header também
                ),
                child: Text(
                  'Ambientes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                title: Text('Sala',
                    style: TextStyle(color: Colors.white)), // Texto branco
                onTap: () {
                  Navigator.pushNamed(context, '/sala_lamp');
                },
              ),
              ListTile(
                title: Text('Suíte Master',
                    style: TextStyle(color: Colors.white)), // Texto branco
                onTap: () {
                  Navigator.pushNamed(context, '/cozinha_lamp');
                },
              ),
              ListTile(
                title: Text('Cozinha',
                    style: TextStyle(color: Colors.white)), // Texto branco
                onTap: () {
                  Navigator.pushNamed(context, '/suite_master_lamp');
                },
              ),
              Divider(color: Colors.white), // Divider branco
              ListTile(
                title: Text('Cenas',
                    style: TextStyle(color: Colors.white)), // Texto branco
                onTap: () {
                  Navigator.pushNamed(context, '/cenas');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmbienteCard extends StatelessWidget {
  final String title;
  final String lampRoute;
  final String iceRoute;
  final String windowRoute;

  AmbienteCard(
      {required this.title,
      required this.lampRoute,
      required this.iceRoute,
      required this.windowRoute});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.lightbulb_outline),
              onPressed: () {
                Navigator.pushReplacementNamed(context, lampRoute);
              },
            ),
            IconButton(
              icon: Icon(Icons.ac_unit),
              onPressed: () {
                Navigator.pushReplacementNamed(context, iceRoute);
              },
            ),
            IconButton(
              icon: Icon(Icons.curtains_closed),
              onPressed: () {
                Navigator.pushReplacementNamed(context, windowRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SalaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala'),
      ),
      body: Center(
        child: Text('Bem-vindo à Sala!'),
      ),
    );
  }
}

class CozinhaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cozinha'),
      ),
      body: Center(
        child: Text('Bem-vindo à Cozinha!'),
      ),
    );
  }
}

class SuiteMasterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suíte Master'),
      ),
      body: Center(
        child: Text('Bem-vindo à Suíte Master!'),
      ),
    );
  }
}

class SalaLampScreen extends StatefulWidget {
  final MqttClient client;
  final String publishTopic;
  final String subscribeTopic;

  SalaLampScreen({
    Key? key,
    required this.client,
    required this.publishTopic,
    required this.subscribeTopic,
  }) : super(key: key);

  @override
  _SalaLampScreenState createState() => _SalaLampScreenState();
}

class _SalaLampScreenState extends State<SalaLampScreen> {
  int numero_de_iluminacoes = 7;
  List<String> _savedTexts = [];
  Map<String, bool> _lampStates = {};
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _initializeSavedTexts();
    _loadSavedTexts();
    _subscribeToFeedbackTopic();
  }

  void _initializeSavedTexts() {
    _savedTexts = [
      'spot sala',
      'arandela amarela',
      'suco de maracuja',
      'texto',
      'spot 7',
      'spot 8',
      'erererer',
    ];

    if (numero_de_iluminacoes > _savedTexts.length) {
      _savedTexts
          .addAll(List.filled(numero_de_iluminacoes - _savedTexts.length, ''));
    }
  }

  void _loadSavedTexts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < numero_de_iluminacoes; i++) {
        _savedTexts[i] = prefs.getString('savedText$i') ?? _savedTexts[i];
      }
    });
  }

  void _saveText(int index, String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('savedText$index', text);
  }

  void _editText(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _textController =
            TextEditingController(text: _savedTexts[index]);

        return AlertDialog(
          title: Text('Alterar nome'),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Enter text"),
          ),
          actions: [
            TextButton(
              child: Text('CANCELAR'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SALVAR'),
              onPressed: () {
                setState(() {
                  _savedTexts[index] = _textController.text;
                  _saveText(index, _savedTexts[index]);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleLamp(String message) {
    _publish(message.toUpperCase());
  }

  Future<void> _publish(String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    try {
      widget.client.publishMessage(
          widget.publishTopic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e) {
      print('Exceção ao publicar mensagem: $e');
      setState(() {
        _connectionError = true;
      });
    }
  }

  void _subscribeToFeedbackTopic() {
    try {
      widget.client.subscribe(widget.subscribeTopic, MqttQos.atMostOnce);
      widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        print('Received message: $pt from topic: ${c[0].topic}>');
        _processFeedback(pt);
      });
    } catch (e) {
      print('Exceção receber mensagem: $e');
      setState(() {
        _connectionError = true;
      });
    }
  }

  void _processFeedback(String feedback) {
    RegExp exp = RegExp(r'<(\d{2})([C]\d[LD]){8}>');

    exp.allMatches(feedback).forEach((match) {
      String placa = match.group(1)!;
      String canaisEstados = match.group(0)!;

      for (int i = 0; i < 8; i++) {
        String canal = canaisEstados.substring(3 + i * 3, 5 + i * 3);
        String estado = canaisEstados.substring(5 + i * 3, 6 + i * 3);

        setState(() {
          _lampStates['$canal$placa'] = estado == 'L';
        });

        if (estado == 'L') {
          print('placa:$placa, Canal ${i + 1}: Ligado');
        } else if (estado == 'D') {
          print('placa:$placa, Canal ${i + 1}: Desligado');
        }
      }
    });
  }

  Widget buildLampControl(int index, String canal_placa) {
    Color lampColor =
        _lampStates[canal_placa] == true ? Colors.yellow : Colors.grey;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _editText(index),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10.0), // Adiciona espaço à esquerda do texto
              child: Text(
                _savedTexts[index],
                style: TextStyle(
                  fontSize: 18,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _connectionError
              ? null
              : () {
                  _toggleLamp('OFON$canal_placa');
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 56, 103, 141), // Azul
            foregroundColor: Colors.white, // Texto branco
          ),
          child: Text('ON'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _connectionError
              ? null
              : () {
                  _toggleLamp('OFFF$canal_placa');
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 56, 103, 141), // Azul
            foregroundColor: Colors.white, // Texto branco
          ),
          child: Text('OFF'),
        ),
        SizedBox(width: 10),
        Icon(
          Icons.lightbulb_outline,
          size: 30,
          color: lampColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/ambientes');
        return false;
      },
      child: Scaffold(
        endDrawer: Drawer(
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.5, // Define o menu para abrir até o meio da página
            color: Colors.black
                .withOpacity(0.9), // Define o fundo preto com transparência
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withOpacity(0.8), // Fundo preto para o header também
                  ),
                  child: Text(
                    'Ambientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Sala',
                      style: TextStyle(color: Colors.white)), // Texto branco
                  onTap: () {
                    Navigator.pushNamed(context, '/sala_lamp');
                  },
                ),
                ListTile(
                  title: Text('Suíte Master',
                      style: TextStyle(color: Colors.white)), // Texto branco
                  onTap: () {
                    Navigator.pushNamed(context, '/suite_master_lamp');
                  },
                ),
                ListTile(
                  title: Text('Cozinha',
                      style: TextStyle(color: Colors.white)), // Texto branco
                  onTap: () {
                    Navigator.pushNamed(context, '/cozinha_lamp');
                  },
                ),
                Divider(color: Colors.white), // Divider branco
                ListTile(
                  title: Text('Cenas',
                      style: TextStyle(color: Colors.white)), // Texto branco
                  onTap: () {
                    Navigator.pushNamed(context, '/cenas');
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Container para o background
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/background.jpg'), // Caminho da sua imagem de fundo
                  fit: BoxFit.cover, // Faz com que a imagem cubra toda a tela
                ),
              ),
              constraints: BoxConstraints
                  .expand(), // Garante que o container cobre toda a tela
            ),
            // AppBar personalizado
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text(
                  'SALA',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Cor do texto
                  ),
                ),
                centerTitle: true, // Centraliza o título
                backgroundColor:
                    Colors.transparent, // Torna o fundo do AppBar transparente
                elevation: 0, // Remove a sombra
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/ambientes');
                  },
                ),
                actions: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Centraliza o conteúdo e remove o espaço extra
            Padding(
              padding: const EdgeInsets.only(
                  top: 100.0), // Ajuste a margem superior conforme necessário
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alinha os itens à esquerda
                children: [
                  buildLampControl(0, 'C101'),
                  buildLampControl(1, 'C201'),
                  buildLampControl(2, 'C301'),
                  buildLampControl(3, 'C401'),
                  buildLampControl(4, 'C501'),
                  buildLampControl(5, 'C601'),
                  buildLampControl(6, 'C701'),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 200, 200, 200),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'lampControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/sala_lamp');
                        },
                        child: Icon(Icons.lightbulb_outline),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                      SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'iceControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/sala_ice');
                        },
                        child: Icon(Icons.ac_unit),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                      SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'curtainControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, '/sala_window');
                        },
                        child: Icon(Icons.curtains_closed),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CozinhaLampScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cozinha - Lâmpada'),
      ),
      body: Center(
        child: Text('Controle da lâmpada da Cozinha!'),
      ),
    );
  }
}

class SuiteMasterLampScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suíte Master - Lâmpada'),
      ),
      body: Center(
        child: Text('Controle da lâmpada da Suíte Master!'),
      ),
    );
  }
}

class SalaIceScreen extends StatefulWidget {
  @override
  _SalaIceScreenState createState() => _SalaIceScreenState();
}

class _SalaIceScreenState extends State<SalaIceScreen> {
  bool isOn = false;
  int temperature = 24;
  String mode = 'Auto';
  bool isColdMode = true; // Inicialmente frio
  int fanSpeed = 0; // 0: off, 1: vel1, 2: vel2, 3: vel3, 4: auto

  void togglePower() {
    setState(() {
      isOn = !isOn;
      sendCommand('power', isOn ? 'on' : 'off');
    });
  }

  void increaseTemperature() {
    setState(() {
      if (isOn && temperature < 30) {
        temperature++;
        sendCommand(
            'temperature', '${temperature}_${isColdMode ? 'cool' : 'hot'}');
      }
    });
  }

  void decreaseTemperature() {
    setState(() {
      if (isOn && temperature > 16) {
        temperature--;
        sendCommand(
            'temperature', '${temperature}_${isColdMode ? 'cool' : 'hot'}');
      }
    });
  }

  void changeMode(String newMode) {
    setState(() {
      if (isOn) {
        mode = newMode;
        sendCommand('mode', mode);
      }
    });
  }

  void toggleFan() {
    setState(() {
      if (isOn) {
        fanSpeed = (fanSpeed + 1) % 5; // Cicla entre 0 e 4
        if (fanSpeed == 4) {
          sendCommand('fan', 'auto');
        } else {
          if (fanSpeed == 0) {
            fanSpeed = 1; // Retorna para vel1 ao invés de 0
          }
          sendCommand('fan', 'vel$fanSpeed');
        }
      }
    });
  }

  Future<void> sendCommand(String command, String value) async {
    String url = generateCommandUrl(command, value);
    print(url);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('Comando enviado com sucesso.!!!');
    } else {
      print('XXX Falha ao enviar comando XXX.');
    }
  }

  String generateCommandUrl(String command, String value) {
    const String link = 'https://cacmd2.controlartcloud.com.br/p2pca?tc=';
    const String key_controlart =
        'teste/'; // lembrar de colocar barra '/' no final.

    Map<String, String> commandUrls = {
      'power_on': 'comando padrão power_on',
      'power_off': 'comando padrão power_off',
      // Comandos de temperatura para modo frio
      'temperature_16_cool': 'comando padrão 16 cool',
      'temperature_17_cool': 'comando padrão 17 cool',
      'temperature_18_cool': 'comando padrão 18 cool',
      'temperature_19_cool': 'comando padrão 19 cool',
      'temperature_20_cool': 'comando padrão 20 cool',
      'temperature_21_cool': 'comando padrão 21 cool',
      'temperature_22_cool': 'comando padrão 22 cool',
      'temperature_23_cool': 'comando padrão 23 cool',
      'temperature_24_cool': 'comando padrão 24 cool',
      'temperature_25_cool': 'comando padrão 25 cool',
      'temperature_26_cool': 'comando padrão 26 cool',
      'temperature_27_cool': 'comando padrão 27 cool',
      'temperature_28_cool': 'comando padrão 28 cool',
      'temperature_29_cool': 'comando padrão 29 cool',
      'temperature_30_cool': 'comando padrão 30 cool',
      // Comandos de temperatura para modo quente
      'temperature_16_hot': 'comando padrão 16 hot',
      'temperature_17_hot': 'comando padrão 17 hot',
      'temperature_18_hot': 'comando padrão 18 hot',
      'temperature_19_hot': 'comando padrão 19 hot',
      'temperature_20_hot': 'comando padrão 20 hot',
      'temperature_21_hot': 'comando padrão 21 hot',
      'temperature_22_hot': 'comando padrão 22 hot',
      'temperature_23_hot': 'comando padrão 23 hot',
      'temperature_24_hot': 'comando padrão 24 hot',
      'temperature_25_hot': 'comando padrão 25 hot',
      'temperature_26_hot': 'comando padrão 26 hot',
      'temperature_27_hot': 'comando padrão 27 hot',
      'temperature_28_hot': 'comando padrão 28 hot',
      'temperature_29_hot': 'comando padrão 29 hot',
      'temperature_30_hot': 'comando padrão 30 hot',
      'fan_vel1': 'comando padrão fan vel1',
      'fan_vel2': 'comando padrão fan vel2',
      'fan_vel3': 'comando padrão fan vel3',
      'fan_auto': 'comando padrão fan auto',
    };

    return '$link$key_controlart${commandUrls['${command}_${value}']}';
  }

  Widget buildButton(String label, VoidCallback onPressed,
      {IconData? icon, double size = 24.0}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 56, 103, 141),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
      ),
      child: icon != null
          ? Icon(icon, color: Color.fromARGB(255, 0, 0, 0), size: size)
          : Text(label, style: TextStyle(fontSize: 16.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, '/ambientes', (route) => false);
        return false;
      },
      child: Scaffold(
        endDrawer: Drawer(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            color: Colors.black.withOpacity(0.9),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: Text(
                    'Ambientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Sala', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/sala_lamp');
                  },
                ),
                ListTile(
                  title: Text('Suíte Master',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/suite_master_lamp');
                  },
                ),
                ListTile(
                  title: Text('Cozinha', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cozinha_lamp');
                  },
                ),
                Divider(color: Colors.white),
                ListTile(
                  title: Text('Cenas', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cenas');
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text('AR SALA',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/ambientes', (route) => false);
                  },
                ),
                actions: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isOn ? '$temperature°C' : '--°C',
                                    style: TextStyle(
                                        fontSize: 48, color: Colors.black),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    isColdMode ? Icons.ac_unit : Icons.wb_sunny,
                                    size: 48,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                              Text(
                                isOn ? (isColdMode ? 'Frio' : 'Quente') : 'Off',
                                style: TextStyle(
                                    fontSize: 24, color: Colors.black),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.fan,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 10),
                                  if (fanSpeed > 0 && fanSpeed < 4) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          List.generate(fanSpeed, (index) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.air,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                  if (fanSpeed == 4)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.sync,
                                        size: 40,
                                        color: Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        buildButton('On/Off', togglePower,
                            icon: Icons.power_settings_new),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildButton(
                              isColdMode ? 'FRIO' : 'QUENTE',
                              () => setState(() {
                                isColdMode = !isColdMode;
                                sendCommand(
                                    'mode', isColdMode ? 'cool' : 'hot');
                              }),
                              icon: isColdMode ? Icons.ac_unit : Icons.wb_sunny,
                            ),
                            SizedBox(width: 10),
                            buildButton('+', increaseTemperature,
                                icon: Icons.add, size: 25),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildButton('Fan', toggleFan,
                                icon: FontAwesomeIcons.fan),
                            SizedBox(width: 10),
                            buildButton('-', decreaseTemperature,
                                icon: Icons.remove, size: 25)
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 200, 200, 200),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'lampControl',
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/sala_lamp');
                            },
                            child: Icon(Icons.lightbulb_outline,
                                color: Colors.black),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            highlightElevation: 0,
                          ),
                          SizedBox(width: 16),
                          FloatingActionButton(
                            heroTag: 'iceControl',
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/sala_ice');
                            },
                            child: Icon(Icons.ac_unit, color: Colors.black),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            highlightElevation: 0,
                          ),
                          SizedBox(width: 16),
                          FloatingActionButton(
                            heroTag: 'curtainControl',
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/sala_window');
                            },
                            child: Icon(Icons.curtains_closed,
                                color: Colors.black),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            highlightElevation: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CozinhaIceScreen extends StatefulWidget {
  @override
  _CozinhaIceScreenState createState() => _CozinhaIceScreenState();
}

class _CozinhaIceScreenState extends State<CozinhaIceScreen> {
  bool isOn = false;
  int temperature = 24;
  String mode = 'Auto';
  bool isFanOn = false;
  bool isFastModeOn = false;

  void togglePower() {
    setState(() {
      isOn = !isOn;
    });
  }

  void increaseTemperature() {
    setState(() {
      if (isOn && temperature < 30) {
        temperature++;
      }
    });
  }

  void decreaseTemperature() {
    setState(() {
      if (isOn && temperature > 16) {
        temperature--;
      }
    });
  }

  void changeMode(String newMode) {
    setState(() {
      if (isOn) {
        mode = newMode;
      }
    });
  }

  void toggleFan() {
    setState(() {
      if (isOn) {
        isFanOn = !isFanOn;
      }
    });
  }

  void toggleFastMode() {
    setState(() {
      if (isOn) {
        isFastModeOn = !isFastModeOn;
      }
    });
  }

  Widget buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala - Floco de Gelo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Text(
                    isOn
                        ? (mode == 'Cool'
                            ? 'Frio'
                            : mode == 'Heat'
                                ? 'Quente'
                                : '')
                        : 'Off',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    isOn ? '$temperature°C' : '--°C',
                    style: TextStyle(fontSize: 48),
                  ),
                  Text(
                    isOn
                        ? (mode == 'Cool'
                            ? 'Frio'
                            : mode == 'Heat'
                                ? 'Quente'
                                : '')
                        : 'Off',
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('On/Off', togglePower),
                SizedBox(width: 10),
                buildButton('Mode', () {
                  changeMode(mode == 'Auto'
                      ? 'Cool'
                      : mode == 'Cool'
                          ? 'Dry'
                          : mode == 'Dry'
                              ? 'Fan'
                              : mode == 'Fan'
                                  ? 'Heat'
                                  : 'Auto');
                }),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Temp-', decreaseTemperature),
                SizedBox(width: 10),
                buildButton('Temp+', increaseTemperature),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Fan', toggleFan),
                SizedBox(width: 10),
                buildButton('Fast', toggleFastMode),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Fan', () {}),
                SizedBox(width: 10),
                buildButton('Timer', () {}),
                SizedBox(width: 10),
                buildButton('Option', () {}),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: Text('SET'),
            ),
          ],
        ),
      ),
    );
  }
}

class SuiteMasterIceScreen extends StatefulWidget {
  @override
  _SuiteMasterIceScreenState createState() => _SuiteMasterIceScreenState();
}

class _SuiteMasterIceScreenState extends State<SuiteMasterIceScreen> {
  bool isOn = false;
  int temperature = 24;
  String mode = 'Auto';
  bool isFanOn = false;
  bool isFastModeOn = false;

  void togglePower() {
    setState(() {
      isOn = !isOn;
    });
  }

  void increaseTemperature() {
    setState(() {
      if (isOn && temperature < 30) {
        temperature++;
      }
    });
  }

  void decreaseTemperature() {
    setState(() {
      if (isOn && temperature > 16) {
        temperature--;
      }
    });
  }

  void changeMode(String newMode) {
    setState(() {
      if (isOn) {
        mode = newMode;
      }
    });
  }

  void toggleFan() {
    setState(() {
      if (isOn) {
        isFanOn = !isFanOn;
      }
    });
  }

  void toggleFastMode() {
    setState(() {
      if (isOn) {
        isFastModeOn = !isFastModeOn;
      }
    });
  }

  Widget buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala - Floco de Gelo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Text(
                    isOn ? 'Set' : '',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    isOn ? '$temperature°C' : '--°C',
                    style: TextStyle(fontSize: 48),
                  ),
                  Text(
                    isOn ? mode : 'Off',
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('On/Off', togglePower),
                SizedBox(width: 10),
                buildButton('Mode', () {
                  changeMode(mode == 'Auto'
                      ? 'Cool'
                      : mode == 'Cool'
                          ? 'Dry'
                          : mode == 'Dry'
                              ? 'Fan'
                              : mode == 'Fan'
                                  ? 'Heat'
                                  : 'Auto');
                }),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Temp-', decreaseTemperature),
                SizedBox(width: 10),
                buildButton('Temp+', increaseTemperature),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Fan', toggleFan),
                SizedBox(width: 10),
                buildButton('Fast', toggleFastMode),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('Fan', () {}),
                SizedBox(width: 10),
                buildButton('Timer', () {}),
                SizedBox(width: 10),
                buildButton('Option', () {}),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: Text('SET'),
            ),
          ],
        ),
      ),
    );
  }
}

class SalaWindowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, '/ambientes', (route) => false);
        return false;
      },
      child: Scaffold(
        endDrawer: Drawer(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            color: Colors.black.withOpacity(0.9),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: Text(
                    'Ambientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Sala', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/sala_lamp');
                  },
                ),
                ListTile(
                  title: Text('Suíte Master',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/suite_master_lamp');
                  },
                ),
                ListTile(
                  title: Text('Cozinha', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cozinha_lamp');
                  },
                ),
                Divider(color: Colors.white),
                ListTile(
                  title: Text('Cenas', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(context, '/cenas');
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Container para o background
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // AppBar personalizado
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text(
                  'CORTINAS SALA',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/ambientes', (route) => false);
                  },
                ),
                actions: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Conteúdo da tela
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 80),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCortinaControl('cortina_1', 'Cortina 1'),
                        buildCortinaControl('cortina_2', 'Cortina 2'),
                        buildCortinaControl('cortina_3', 'Cortina 3'),
                        buildCortinaControl('cortina_4', 'Cortina 4'),
                      ],
                    ),
                  ),
                  SizedBox(height: 60),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 200, 200, 200),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'lampControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/sala_lamp');
                        },
                        child:
                            Icon(Icons.lightbulb_outline, color: Colors.black),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                      SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'iceControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/sala_ice');
                        },
                        child: Icon(Icons.ac_unit, color: Colors.black),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                      SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'curtainControl',
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, '/sala_window');
                        },
                        child: Icon(Icons.curtains_closed, color: Colors.black),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        highlightElevation: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCortinaControl(String cortinaNome, String cortinaLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            cortinaLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'abrir');
                },
                child: Text('Abrir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 56, 103, 141),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'fechar');
                },
                child: Text('Fechar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 56, 103, 141),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'parar');
                },
                child: Text('Parar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 56, 103, 141),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget buildCortinaControl(String cortinaNome, String cortinaLabel) {
  return Padding(
    padding: const EdgeInsets.symmetric(
        vertical: 12.0), // Aumenta o espaço entre os itens
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          cortinaLabel,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(
                  255, 255, 255, 255)), // Cor do texto branca
        ),
        Row(
          mainAxisSize: MainAxisSize.min, // Para não expandir a linha
          children: [
            ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'abrir');
                },
                child: Text('Abrir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(
                      255, 56, 103, 141), // Cor de fundo dos botões
                  foregroundColor: Colors.white, // Cor do texto dos botões
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                )),
            SizedBox(width: 8),
            ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'fechar');
                },
                child: Text('Fechar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(
                      255, 56, 103, 141), // Cor de fundo dos botões
                  foregroundColor: Colors.white, // Cor do texto dos botões
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                )),
            SizedBox(width: 8),
            ElevatedButton(
                onPressed: () {
                  sendCommand(cortinaNome, 'parar');
                },
                child: Text('Parar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(
                      255, 56, 103, 141), // Cor de fundo dos botões
                  foregroundColor: Colors.white, // Cor do texto dos botões
                  padding:
                      EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                )),
          ],
        ),
      ],
    ),
  );
}

void sendCommand(String cortinaNome, String acao) async {
  String comando = generateCommand(cortinaNome, acao);

  // Envia o comando remotamente
  final response = await http.get(Uri.parse(comando));
  print(comando);
  if (response.statusCode == 200) {
    print('Comando enviado remotamente com sucesso!');
  } else {
    print('Falha ao enviar comando remotamente.');
  }
}

String generateCommand(String cortinaNome, String acao) {
  const String linkPrefix = 'https://cacmd2.controlartcloud.com.br/p2pca?tc=';
  const String keyPrefix = 'teste/'; // lembrar de colocar a barra '/' no final

  Map<String, Map<String, String>> comandos = {
    'cortina_1': {
      'abrir': 'comando_abrir_cortina_1',
      'fechar': 'comando_fechar_cortina_1',
      'parar': 'comando_parar_cortina_1',
    },
    'cortina_2': {
      'abrir': 'comando_abrir_cortina_2',
      'fechar': 'comando_fechar_cortina_2',
      'parar': 'comando_parar_cortina_2',
    },
    'cortina_3': {
      'abrir': 'comando_abrir_cortina_3',
      'fechar': 'comando_fechar_cortina_3',
      'parar': 'comando_parar_cortina_3',
    },
    'cortina_4': {
      'abrir': 'comando_abrir_cortina_4',
      'fechar': 'comando_fechar_cortina_4',
      'parar': 'comando_parar_cortina_4',
    },
  };

  return '$linkPrefix$keyPrefix${comandos[cortinaNome]?[acao] ?? 'comando_padrao'}';
}

class CozinhaWindowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cozinha - Cortinas'),
      ),
      body: Center(
        child: Text('Controle da Cortinas da Cozinha!'),
      ),
    );
  }
}

class SuiteMasterWindowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suíte Master - Cortinas'),
      ),
      body: Center(
        child: Text('Controle da Cortinas da Suíte Master!'),
      ),
    );
  }
}

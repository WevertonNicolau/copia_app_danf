import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  String publishTopic = '/Danf/TESTEBARRACAOCAMPO/V3/Mqtt/Comando';
  String subscribeTopic = '/Danf/TESTEBARRACAOCAMPO/V3/Mqtt/Feedback';

  MqttServerClient? client;
  bool _connected = false;
  Timer? _timer;

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
    Future.delayed(Duration(seconds: 1), () {
      if (!_connected) {
        _connect();
      }
    });
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
        home: HomeScreen(isMqttConnected: _connected),
        routes: {
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

class HomeScreen extends StatelessWidget {
  final bool isMqttConnected;

  HomeScreen({required this.isMqttConnected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tela Inicial'),
      ),
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/ambientes');
                },
                child: Text(
                  'Entrar',
                  style: TextStyle(color: Colors.black), // Cor do texto preta
                ),
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
                        color: const Color.fromARGB(
                            255, 255, 255, 255)), // Cor do texto preta
                  ),
                  Icon(
                    Icons.circle,
                    color: isMqttConnected ? Colors.green : Colors.red,
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

class AmbientesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ambientes'),
      ),
      body: Container(
        width: double.infinity, // Garante que o Container ocupe toda a largura
        height: double.infinity, // Garante que o Container ocupe toda a altura
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/background.jpg'), // Substitua pelo caminho da sua imagem
            fit: BoxFit
                .cover, // Faz com que a imagem cubra toda a área disponível
          ),
        ),
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
            child: Text(
              _savedTexts[index],
              style: TextStyle(
                fontSize: 18,
                color: const Color.fromARGB(255, 255, 255, 255),
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
          child: Text('ON'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _connectionError
              ? null
              : () {
                  _toggleLamp('OFFF$canal_placa');
                },
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
        appBar: AppBar(
          title: Text('Sala - Lâmpada'),
        ),
        body: BackgroundScaffold(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                      color: Colors.white,
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
                          child: Icon(Icons.lightbulb_outline),
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, '/ambientes', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sala - Floco de Gelo'),
        ),
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.8), // Fundo branco com transparência
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isOn ? 'Set' : '',
                          style: TextStyle(fontSize: 24, color: Colors.black),
                        ),
                        Text(
                          isOn ? '$temperature°C' : '--°C',
                          style: TextStyle(fontSize: 48, color: Colors.black),
                        ),
                        Text(
                          isOn ? mode : 'Off',
                          style: TextStyle(fontSize: 24, color: Colors.black),
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
        appBar: AppBar(
          title: Text('Sala - Cortinas'),
        ),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCortinaControl(0, 'Cortina 1'),
                  buildCortinaControl(1, 'Cortina 2'),
                  buildCortinaControl(2, 'teste 3'),
                  buildCortinaControl(3, 'Cortina 4'),
                  Expanded(
                    child: Center(
                      child: Text(
                        '',
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(
                                255, 255, 255, 255)), // Cor do texto preta
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                              child: Icon(Icons.lightbulb_outline),
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
          ],
        ),
      ),
    );
  }

  Widget buildCortinaControl(int index, String cortinaNome) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            cortinaNome,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(
                    255, 255, 255, 255)), // Cor do texto preta
          ),
          ElevatedButton(
            onPressed: () {
              sendCommand(index, cortinaNome, 'abrir');
            },
            child: Text('Abrir'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              sendCommand(index, cortinaNome, 'fechar');
            },
            child: Text('Fechar'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              sendCommand(index, cortinaNome, 'parar');
            },
            child: Text('Parar'),
          ),
        ],
      ),
    );
  }

  void sendCommand(int index, String cortinaNome, String acao) async {
    String comando = generateCommand(index, acao);

    // Envia o comando remotamente
    final response = await http.get(Uri.parse(comando));
    if (response.statusCode == 200) {
      print(
          'Comando enviado remotamente com sucesso!###############################################################################################################');
    } else {
      print('Falha ao enviar comando remotamente.');
    }
  }

  String generateCommand(int index, String acao) {
    // Defina aqui os comandos específicos para cada cortina e ação
    Map<int, Map<String, String>> comandos = {
      0: {
        'abrir':
            'https://cacmd2.controlartcloud.com.br/p2pca?tc=RHhIQ1oiU2uYQPscTQ/sendir,1:1,1,38616,67,16,2016,24,16,24,16,67,16,24,16,2000', //controlart do carlos cruzich
        'fechar': 'http://your-server.com/comando_fechar_cortina_1',
        'parar': 'http://your-server.com/comando_parar_cortina_1',
      },
      1: {
        'abrir': 'http://your-server.com/comando_abrir_cortina_2',
        'fechar': 'http://your-server.com/comando_fechar_cortina_2',
        'parar': 'http://your-server.com/comando_parar_cortina_2',
      },
      2: {
        'abrir': 'http://your-server.com/comando_abrir_cortina_3',
        'fechar': 'http://your-server.com/comando_fechar_cortina_3',
        'parar': 'http://your-server.com/comando_parar_cortina_3',
      },
      3: {
        'abrir': 'http://your-server.com/comando_abrir_cortina_4',
        'fechar': 'http://your-server.com/comando_fechar_cortina_4',
        'parar': 'http://your-server.com/comando_parar_cortina_4',
      },
    };

    return comandos[index]?[acao] ?? 'http://your-server.com/comando_padrao';
  }
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

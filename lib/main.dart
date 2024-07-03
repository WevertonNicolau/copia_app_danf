import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String publishTopic = '/Danf/TESTE_2024/V3/Mqtt/Comando';
  String subscribeTopic = '/Danf/TESTE_2024/V3/Mqtt/Feedback';

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
    }

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');
    });

    _subscribeToTopic(subscribeTopic);
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
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  Future<void> _publish(String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(publishTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
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
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tela Inicial'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/ambientes');
          },
          child: Text('Entrar'),
        ),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmbienteCard(
                title: 'Sala',
                lampRoute: '/sala_lamp',
                iceRoute: '/sala_ice',
                windowRoute: '/sala_window'),
            AmbienteCard(
                title: 'Cozinha',
                lampRoute: '/cozinha_lamp',
                iceRoute: '/cozinha_ice',
                windowRoute: '/cozinha_window'),
            AmbienteCard(
                title: 'Suíte Master',
                lampRoute: '/suite_master_lamp',
                iceRoute: '/suite_master_ice',
                windowRoute: '/suite_master_window'),
            // Adicione mais abas conforme necessário
          ],
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
                Navigator.pushNamed(context, lampRoute);
              },
            ),
            IconButton(
              icon: Icon(Icons.ac_unit),
              onPressed: () {
                Navigator.pushNamed(context, iceRoute);
              },
            ),
            IconButton(
              icon: Icon(Icons.curtains_closed),
              onPressed: () {
                Navigator.pushNamed(context, windowRoute);
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
  final MqttServerClient client;
  final String subscribeTopic;
  final String publishTopic;

  SalaLampScreen({
    required this.client,
    required this.subscribeTopic,
    required this.publishTopic,
  });

  @override
  _SalaLampScreenState createState() => _SalaLampScreenState();
}

class _SalaLampScreenState extends State<SalaLampScreen> {
  String _savedText = 'Texto editável';
  bool _lampState = false;
  Color _lampColor = Colors.grey; // Inicialmente branco

  @override
  void initState() {
    super.initState();
    _loadSavedText();
    _subscribeToFeedbackTopic();
  }

  void _loadSavedText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedText = prefs.getString('savedText') ?? 'Texto editável';
    });
  }

  void _saveText(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('savedText', text);
  }

  void _editText() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _textController =
            TextEditingController(text: _savedText);

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
                  _savedText = _textController.text;
                  _saveText(_savedText);
                });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala - Lâmpada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _editText,
                    child: Text(
                      _savedText,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _toggleLamp(true);
                  },
                  child: Text('ON'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _toggleLamp(false);
                  },
                  child: Text('OFF'),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.lightbulb_outline,
                  size: 30,
                  color: _lampColor, // Cor dinâmica da lâmpada
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text('Controle da lâmpada da Sala!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribeToFeedbackTopic() {
    widget.client.subscribe(widget.subscribeTopic, MqttQos.atMostOnce);
    widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');
      _processFeedback(pt);
    });
  }

  void _processFeedback(String feedback) {
    // Expressão regular para extrair as informações de cada placa e canal
    RegExp exp = RegExp(r'<(\d{2})([CD]\d[L|D]){8}>');

    // Encontrar todos os matches no feedback
    Iterable<Match> matches = exp.allMatches(feedback);

    // Iterar sobre cada match encontrado
    matches.forEach((match) {
      // Extrair número da placa
      String plateNumber = match.group(1)!;
      // Extrair informações de cada canal
      for (int i = 0; i < 8; i++) {
        String channelInfo = match.group(i + 2)!;
        // Extrair número do canal
        int channelNumber = int.parse(channelInfo.substring(1, 2));
        // Verificar estado do canal (ligado/desligado)
        bool isChannelOn = channelInfo.endsWith('L');

        // Verificar se é o canal desejado (canal 2 da placa 1)
        if (plateNumber == '01' && channelNumber == 2) {
          // Atualizar cor da lâmpada baseado no estado do canal
          setState(() {
            _lampColor = isChannelOn ? Colors.yellow : Colors.grey;
          });
        }
      }
    });
  }

  void _toggleLamp(bool on) {
    String message = on
        ? 'OFONC201'
        : 'OFFFC201'; // Comando MQTT para ligar ou desligar a lâmpada (canal 2 da placa 1)
    _publish(message);
  }

  Future<void> _publish(String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(
        widget.publishTopic, MqttQos.atLeastOnce, builder.payload!);
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
  bool isEconomyMode = false;

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

  void toggleEconomyMode() {
    setState(() {
      if (isOn) {
        isEconomyMode = !isEconomyMode;
      }
    });
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
              child: Text(
                '$temperature°C',
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: togglePower,
              child: Text(isOn ? 'Desligar' : 'Ligar'),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: decreaseTemperature,
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: increaseTemperature,
                  child: Text('+'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: toggleEconomyMode,
              child: Text(isEconomyMode ? 'Modo Normal' : 'Modo Economia'),
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
  bool isEconomyMode = false;

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

  void toggleEconomyMode() {
    setState(() {
      if (isOn) {
        isEconomyMode = !isEconomyMode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cozinha - Floco de Gelo'),
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
              child: Text(
                '$temperature°C',
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: togglePower,
              child: Text(isOn ? 'Desligar' : 'Ligar'),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: decreaseTemperature,
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: increaseTemperature,
                  child: Text('+'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: toggleEconomyMode,
              child: Text(isEconomyMode ? 'Modo Normal' : 'Modo Economia'),
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
  bool isEconomyMode = false;

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

  void toggleEconomyMode() {
    setState(() {
      if (isOn) {
        isEconomyMode = !isEconomyMode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suíte Master - Floco de Gelo'),
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
              child: Text(
                '$temperature°C',
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: togglePower,
              child: Text(isOn ? 'Desligar' : 'Ligar'),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: decreaseTemperature,
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: increaseTemperature,
                  child: Text('+'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: toggleEconomyMode,
              child: Text(isEconomyMode ? 'Modo Normal' : 'Modo Economia'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala - Cortinas'),
      ),
      body: Center(
        child: Text('Controle da Cortinas da Sala!'),
      ),
    );
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

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
  final MqttClient client;
  final String publishTopic;
  final String subscribeTopic;

  SalaLampScreen({
    required this.client,
    required this.publishTopic,
    required this.subscribeTopic,
  });

  @override
  _SalaLampScreenState createState() => _SalaLampScreenState();
}

class _SalaLampScreenState extends State<SalaLampScreen> {
  List<String> _savedTexts =
      List.generate(6, (index) => 'Texto editável ${index + 1}');
  List<Color> _lampColors = List.generate(6, (index) => Colors.grey);

  @override
  void initState() {
    super.initState();
    _loadSavedTexts();
    _subscribeToFeedbackTopic();
  }

  void _loadSavedTexts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 6; i++) {
        _savedTexts[i] =
            prefs.getString('savedText$i') ?? 'Texto editável ${i + 1}';
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
    message.toUpperCase(); // Comando MQTT para ligar ou desligar a lâmpada
    _publish(message.toUpperCase());
  }

  Future<void> _publish(String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(
        widget.publishTopic, MqttQos.atLeastOnce, builder.payload!);
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
    RegExp exp = RegExp(r'<(\d{2})([CD]\d[LD]){8}>');

    // Iterar sobre as correspondências encontradas
    exp.allMatches(feedback).forEach((match) {
      String placa = match.group(1)!; // Extrair o número da placa
      String canaisEstados =
          match.group(0)!; // Extrair a string completa de canais e estados

      // Iterar sobre cada par de canal e estado dentro da string
      for (int i = 0; i < 8; i++) {
        String canal = canaisEstados.substring(3 + i * 3, 5 + i * 3);
        String estado = canaisEstados.substring(5 + i * 3, 6 + i * 3);

        // Verificar se é o canal desejado e se está ligado
        if (canal == feedback.substring(0, 2) && estado == 'L') {
          // Trocar a cor da lâmpada se o canal correspondente estiver ligado
          int index = int.parse(canal.substring(1, 2)) -
              1; // Índice na lista _lampColors
          if (index >= 0 && index < _lampColors.length) {
            _trocarCorLampada(index);
          }
        }

        // Imprimir o estado do canal
        if (estado == 'L') {
          print('placa:$placa, Canal ${i + 1}: Ligado');
        } else if (estado == 'D') {
          print('placa:$placa, Canal ${i + 1}: Desligado');
        }
      }
    });
  }

  void _trocarCorLampada(int index) {
    // Implementar a lógica para trocar a cor da lâmpada
    setState(() {
      switch (index) {
        case 0:
          _lampColors[index] = Colors.red;
          break;
        case 1:
          _lampColors[index] = Colors.green;
          break;
        case 2:
          _lampColors[index] = Colors.blue;
          break;
        case 3:
          _lampColors[index] = Colors.yellow;
          break;
        case 4:
          _lampColors[index] = Colors.orange;
          break;
        case 5:
          _lampColors[index] = Colors.purple;
          break;
        default:
          print('Índice de lâmpada não suportado para troca de cor.');
      }
    });
  }

  Widget buildLampControl(int index, String canal_placa) {
    // Extrair o número do canal e da placa
    String placa = canal_placa.substring(2, 3); // Ex: 'C301' -> '01'
    String canal = canal_placa.substring(0, 1); // Ex: 'C301' -> '3'

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _editText(index),
            child: Text(
              _savedTexts[index],
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _toggleLamp('OFON$canal_placa');
          },
          child: Text('ON'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            _toggleLamp('OFFF$canal_placa');
          },
          child: Text('OFF'),
        ),
        SizedBox(width: 10),
        Icon(
          Icons.lightbulb_outline,
          size: 30,
          color: _lampColors[index],
        ),
      ],
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
            buildLampControl(0, 'C101'),
            buildLampControl(1, 'C201'),
            buildLampControl(2, 'C301'),
            buildLampControl(3, 'C401'),
            buildLampControl(4, 'C501'),
            buildLampControl(5, 'C601'),
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

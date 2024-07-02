import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Home App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MqttServerClient client;

  final String server = 'super-author.cloudmqtt.com';
  final int port = 1883;
  final String username = 'tdmstjgu';
  final String password = 'mBv2M7HusSx8';
  String publishTopic = '/Danf/TESTE_2024/V3/Mqtt/Comando';
  String subscribeTopic = '/Danf/TESTE_2024/V3/Mqtt/Feedback';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    client = MqttServerClient.withPort(server, '#', port);
    client.logging(on: true);

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.onUnsubscribed = onUnsubscribed;
    client.onAutoReconnect = onAutoReconnect;
    client.onAutoReconnected = onAutoReconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      _subscribeToFeedback();
    } on Exception catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void _subscribeToFeedback() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');
    });

    client.subscribe(subscribeTopic, MqttQos.atLeastOnce);
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed from $topic');
  }

  void onAutoReconnect() {
    print('Auto reconnect');
  }

  void onAutoReconnected() {
    print('Auto reconnected');
  }

  void onAutoReconnecting() {
    print('Auto reconnecting');
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenuPage(client)),
            );
          },
          child: Text('Entrar'),
        ),
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  final MqttServerClient client;

  MenuPage(this.client);

  final List<String> rooms = [
    "Sala",
    "Cozinha",
    "Quarto",
    "Banheiro",
    "Escritório"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                title: Text(rooms[index]),
                trailing: IconButton(
                  icon: Icon(Icons.lightbulb_outline),
                  onPressed: () {
                    String roomName = rooms[index];
                    String publishTopic = '/Danf/TESTE_2024/V3/Mqtt/Comando';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            getRoomPage(roomName, client, publishTopic),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget getRoomPage(
      String roomName, MqttServerClient client, String publishTopic) {
    switch (roomName) {
      case "Sala":
        return SalaPage(client: client, publishTopic: publishTopic);
      case "Cozinha":
        return CozinhaPage(client: client, publishTopic: publishTopic);
      case "Quarto":
        return QuartoPage(client: client, publishTopic: publishTopic);
      default:
        return Container(); // Página vazia caso não haja correspondência
    }
  }
}

class SalaPage extends StatefulWidget {
  final MqttServerClient client;
  final String publishTopic;

  SalaPage({required this.client, required this.publishTopic});

  @override
  _SalaPageState createState() => _SalaPageState();
}

class _SalaPageState extends State<SalaPage> {
  bool isLightOn = false;
  TextEditingController _controller = TextEditingController(text: 'spot');

  @override
  void initState() {
    super.initState();
    _loadText();
    _subscribeToFeedback();
  }

  void _loadText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString('Sala') ?? 'spot';
    });
  }

  void _saveText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Sala', _controller.text);
  }

  void _publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(
      widget.publishTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('Mensagem publicada para Sala: $message');
  }

  void _subscribeToFeedback() {
    widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');

      // Processa o feedback recebido para a Sala
      _processFeedback(pt);
    });

    widget.client.subscribe(widget.publishTopic, MqttQos.atLeastOnce);
  }

  void _processFeedback(String feedback) {
    // Implemente aqui o processamento específico para o feedback da Sala
    // Exemplo de processamento:
    if (feedback.contains('<01C1L')) {
      setState(() {
        isLightOn = true;
      });
    } else {
      setState(() {
        isLightOn = false;
      });
    }
  }

  @override
  void dispose() {
    _saveText();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala'),
        leading: BackButton(
          onPressed: () {
            _saveText();
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFONC101'); // Envia comando para ligar na Sala
                  },
                  child: Text('Ligar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFFFC101'); // Envia comando para desligar na Sala
                  },
                  child: Text('Desligar'),
                ),
                SizedBox(width: 10),
                Icon(
                  isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isLightOn ? Colors.yellow : Colors.grey,
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CozinhaPage extends StatefulWidget {
  final MqttServerClient client;
  final String publishTopic;

  CozinhaPage({required this.client, required this.publishTopic});

  @override
  _CozinhaPageState createState() => _CozinhaPageState();
}

class _CozinhaPageState extends State<CozinhaPage> {
  bool isLightOn = false;
  TextEditingController _controller = TextEditingController(text: 'spot');

  @override
  void initState() {
    super.initState();
    _loadText();
    _subscribeToFeedback();
  }

  void _loadText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString('Cozinha') ?? 'spot';
    });
  }

  void _saveText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Cozinha', _controller.text);
  }

  void _publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(
      widget.publishTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('Mensagem publicada para Cozinha: $message');
  }

  void _subscribeToFeedback() {
    widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');

      // Processa o feedback recebido para a Cozinha
      _processFeedback(pt);
    });

    widget.client.subscribe(widget.publishTopic, MqttQos.atLeastOnce);
  }

  void _processFeedback(String feedback) {
    // Define as strings para a placa e o canal
    String placa = '01'; // Substitua com a placa desejada
    String canal = 'C2'; // Substitua com o canal desejado

    // Verifica se o feedback contém a placa e o canal desejados
    if (feedback.contains(placa) && feedback.contains(canal)) {
      // Atualiza o estado da lâmpada conforme o estado atual
      setState(() {
        isLightOn =
            feedback.contains('estado=ligado'); // Exemplo de condição de estado
      });
    }
  }

  @override
  void dispose() {
    _saveText();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cozinha'),
        leading: BackButton(
          onPressed: () {
            _saveText();
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFONC201'); // Envia comando para ligar na Cozinha
                  },
                  child: Text('Ligar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFFFC201'); // Envia comando para desligar na Cozinha
                  },
                  child: Text('Desligar'),
                ),
                SizedBox(width: 10),
                Icon(
                  isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isLightOn ? Colors.yellow : Colors.grey,
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Implemente as classes QuartoPage, BanheiroPage e EscritorioPage de maneira semelhante

class QuartoPage extends StatefulWidget {
  final MqttServerClient client;
  final String publishTopic;

  QuartoPage({required this.client, required this.publishTopic});

  @override
  _QuartoPageState createState() => _QuartoPageState();
}

class _QuartoPageState extends State<QuartoPage> {
  bool isLightOn = false;
  TextEditingController _controller = TextEditingController(text: 'spot');

  @override
  void initState() {
    super.initState();
    _loadText();
    _subscribeToFeedback();
  }

  void _loadText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString('Quarto') ?? 'spot';
    });
  }

  void _saveText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Quarto', _controller.text);
  }

  void _publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(
      widget.publishTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('Mensagem publicada para Quarto: $message');
  }

  void _subscribeToFeedback() {
    widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $pt from topic: ${c[0].topic}>');

      // Processa o feedback recebido para o Quarto
      _processFeedback(pt);
    });

    widget.client.subscribe(widget.publishTopic, MqttQos.atLeastOnce);
  }

  void _processFeedback(String feedback) {
    // Implemente aqui o processamento específico para o feedback do Quarto
    // Exemplo de processamento:
    if (feedback.contains('<01C3L')) {
      setState(() {
        isLightOn = true;
      });
    } else {
      setState(() {
        isLightOn = false;
      });
    }
  }

  @override
  void dispose() {
    _saveText();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quarto'),
        leading: BackButton(
          onPressed: () {
            _saveText();
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFONC301'); // Envia comando para ligar no Quarto
                  },
                  child: Text('Ligar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage(
                        'OFFFC301'); // Envia comando para desligar no Quarto
                  },
                  child: Text('Desligar'),
                ),
                SizedBox(width: 10),
                Icon(
                  isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isLightOn ? Colors.yellow : Colors.grey,
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

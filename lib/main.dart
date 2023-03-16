import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class AdafruitData extends StatefulWidget {
  const AdafruitData({Key? key}) : super(key: key);

  @override
  State<AdafruitData> createState() => _MyApp2State();
}

class _MyApp2State extends State<AdafruitData> {
  String result = '';

  @override
  void initState() {
    getSensorData();
    startTimer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Smart Door Lock', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: Center(
              child: Text(
                result,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: FloatingActionButton(
                  child: Text(
                    'Open',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  onPressed: () {
                    postData('1');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //dashboard
  //https://io.adafruit.com/MonoDevice/dashboards/smart-noor-lock

  //feed
  //https://io.adafruit.com/MonoDevice/feeds/opennoor

  //Get data from feed
  //https://io.adafruit.com/api/v2/MonoDevice/feeds?X-AIO-Key=aio_NKRj53uRKHi7aARjvbiyPz2HFbZJ

  //Adafruit documentation
  //https://io.adafruit.com/api/docs/mqtt.html#adafruit-io-39-s-limitations

  Future postData(String value) async {
    final String jsonString = await rootBundle.loadString('assets/config.json');
    final jsonMap = json.decode(jsonString);
    String apiKey = jsonMap['api_Key'];
    String url = jsonMap['http_URL_Lock'];
    //print(apiKey);
    //print(url);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };
    final body = {
      "datum": {"value": value}
    };

    final response = await http.post(Uri.parse(url),
        headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      // handle success
      await getSensorData();
    } else {
      // handle error
      //print('Error: ${response.statusCode}');
    }
  }

  Future<void> getSensorData() async {
    final String jsonString = await rootBundle.loadString('assets/config.json');
    final jsonMap = json.decode(jsonString);
    String url = jsonMap['get_latest_value'];

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      String lastValue = jsonResponse['last_value'];
      print(lastValue);
      //print(jsonResponse);
      if (lastValue == '1') {
        setState(() {
          result = 'Door is Open';
        });
      } else if (lastValue == '0') {
        setState(() {
          result = 'Door is Locked';
        });
      }
    } else {
      //handle error
      print('Error: ${response.statusCode}');
    }
  }

  void startTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      getSensorData();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Noor Lock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdafruitData(),
      //home: const MqttApp(),
    );
  }
}


class MqttApp extends StatefulWidget {
  const MqttApp({Key? key}) : super(key: key);

  @override
  State<MqttApp> createState() => _MqttAppState();
}

class _MqttAppState extends State<MqttApp> {
  var mqtt = MqttConnection(1883, 'API_KEY');
  final String topic = 'esp/smartnoorlock';
  String result = 'The door is locked';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Smart Door Lock', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: Center(
              child: Text(
                result,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: FloatingActionButton(
                  child: Text(
                    'Open',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  onPressed: () {
                    mqtt.publish(topic);
                    setState(() {
                      mqtt.sub(topic);
                      result = mqtt.lastMessage;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void initState() {
    mqtt.connect();
    super.initState();
  }
}

class MqttConnection {
  final int _port;
  final String _token;
  final MqttServerClient _client = MqttServerClient("mqtt.flespi.io","");
  final builder = MqttClientPayloadBuilder();
  String lastMessage = '';

  MqttConnection(this._port, this._token);

  Future<bool> connect() async {
    _client.port = _port;
    _client.logging(on: true);
    _client.keepAlivePeriod = 30;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier('myClient')
        .withWillTopic('willtopic')
        .withWillMessage('My client disconnected')
        .withWillQos(MqttQos.atLeastOnce)
        .authenticateAs(_token, "")
        .startClean();

    _client.connectionMessage = connMess;

    try {
      await _client.connect();
      print('Connected');
      return true;
    } catch (e) {
      print('Connection failed - $e');
      _client.disconnect();
      print('Disconnected');
      return false;
    }
  }

  void sub(String topic){
    _client.subscribe(topic, MqttQos.atLeastOnce);
    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(pt);
      lastMessage = pt;

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    });
  }


  Future<void> publish(String topic) async{
    builder.addString('Door is now unlocked');
    _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    builder.clear();
    print('Message send');
  }

  void disconnect(){
    _client.disconnect();
  }
}




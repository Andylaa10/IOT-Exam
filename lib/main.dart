import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    //startTimer();
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
      print(jsonResponse);
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
    );
  }
}

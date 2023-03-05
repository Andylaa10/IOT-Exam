import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    PostRequest post = PostRequest();
    return MaterialApp(
      title: 'Smart Noor Lock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: FloatingActionButton(
                    child: Text('Open', style: TextStyle(fontSize: 20, color: Colors.black),),
                    onPressed: ()=> post.postData('1'),
                  ),
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
                    child: Text('Close', style: TextStyle(fontSize: 20, color: Colors.black),),
                    onPressed: ()=> post.postData('0'),
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

class PostRequest {

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
    String url = jsonMap['http_URL'];
    //print(apiKey);
    //print(url);

    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
    final body = {"datum": {"value": value}};

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      // handle success
      print(response.body);
    } else {
      // handle error
      print('Error: ${response.statusCode}');
    }
  }
}

/**
 * This is an exam project in Internet of things (IOT),
 * which is one of the choosen elective courses on 4th semester.
 * We have made a smart door lock, which sends information to flespi mqtt and adafruit io.
 * Adafruit io controls the smart door lock, and flespi mqtt receives data based on the state of the door lock.
 * As a nice to have we have made a fairly simple flutter app which sends post request to adafruit io,
 * so the state of the smart door lock can be changed through the app.
 */


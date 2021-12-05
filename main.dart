import 'package:flutter/material.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:location/location.dart';
import 'dart:ui';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    //cookieManager.clearCookies();
  }

  final cookieManager = WebviewCookieManager();
  late WebViewController controller;
  var _url = 'https://accounts.spotify.com/tr/login';
  bool tokenOK = false;
  bool isVisible = true;
  var spToken = null;
  var myTitle = "";
  var myURL;
  var floaticon;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF191414),
          appBar: AppBar(
            title: Text(myTitle),
            centerTitle: true,
            backgroundColor: const Color(0xFF191414),
            actions: [
              IconButton(
                  onPressed: () async {
                    controller.reload();
                  },
                  icon: const Icon(Icons.refresh))
            ],
          ),
          body: SafeArea(
            child: Visibility(
                visible: isVisible,
                child: WebView(
                    initialUrl: _url,
                    javascriptMode: JavascriptMode.unrestricted,
                    navigationDelegate: (NavigationRequest request) {
                      if (!request.url.startsWith('https://accounts.spotify.com/tr')) {
                        return NavigationDecision.prevent;
                      }
                      return NavigationDecision.navigate;
                    },
                    onWebViewCreated: (WebViewController webViewController) async {
                      try {
                        final result = await InternetAddress.lookup('google.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          print('connected!');
                          setState(() {
                            controller.loadUrl("file:///index.html");
                          });
                        }
                      } on SocketException catch (_) {
                        print('no connection');
                      }
                      controller = webViewController;
                      var currentURL = await controller.currentUrl();
                      if (currentURL == "https://accounts.spotify.com/tr/login") {
                        setState(() {
                          floaticon = Icon(Icons.logout);
                        });
                      }
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      //prefs.remove('token');
                      var token = prefs.getString('token');
                      if (token != null) {
                        Location location = new Location();

                        bool _serviceEnabled;
                        PermissionStatus _permissionGranted;
                        LocationData _locationData;

                        _serviceEnabled = await location.serviceEnabled();
                        if (!_serviceEnabled) {
                          _serviceEnabled = await location.requestService();
                          if (!_serviceEnabled) {
                            return;
                          }
                        }

                        _permissionGranted = await location.hasPermission();
                        if (_permissionGranted == PermissionStatus.denied) {
                          _permissionGranted = await location.requestPermission();
                          if (_permissionGranted != PermissionStatus.granted) {
                            return;
                          }
                        }
                        var loc = await location.getLocation();
                        var a = loc.toString().replaceAll(new RegExp(r'[^\w\s]+'), '').split("LocationData");
                        setState(() => myTitle = "Arkadaş Aktiviten");
                        controller.loadUrl("https://friends.youids.com/friendactivity.php?token=$token&location=$a");
                        print("https://friends.youids.com/friendactivity.php?token=$token&location=$a");
                      } else {
                        setState(() {
                          myTitle = "Spotify ile Oturum Aç";
                        });
                      }
                      var _url = Uri.parse("https://raw.githubusercontent.com/4nat/SPVersion/main/version.xml");
                      final response = await http.get(_url);

                      final document = XmlDocument.parse(response.body);
                      final version = int.parse(document.findAllElements('vercheck').single.text);
                      double myVersion = 1;
                      if (version > myVersion) {
                        print("güncelleme gerekli.");
                        setState(() async {
                          myTitle = "Güncelleme Gerekli!";
                          controller.loadUrl("https://friends.youids.com/update.php");
                          const url = "https://hmstk.me/SPFriends/?update=true";
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        });
                      } else {
                        print("version is up to date");
                      }
                    },
                    onPageFinished: (_) async {
                      Location location = new Location();

                      bool _serviceEnabled;
                      PermissionStatus _permissionGranted;
                      LocationData _locationData;

                      _serviceEnabled = await location.serviceEnabled();
                      if (!_serviceEnabled) {
                        _serviceEnabled = await location.requestService();
                        if (!_serviceEnabled) {
                          return;
                        }
                      }

                      _permissionGranted = await location.hasPermission();
                      if (_permissionGranted == PermissionStatus.denied) {
                        _permissionGranted = await location.requestPermission();
                        if (_permissionGranted != PermissionStatus.granted) {
                          return;
                        }
                      }
                      var loc = await location.getLocation();
                      var a = loc.toString().replaceAll(new RegExp(r'[^\w\s]+'), '').split("LocationData");
                      //print("Token: $spToken");
                      //controller.evaluateJavascript(
                      //'document.getElementsByClassName("row")[0].style.display="none";document.getElementsByClassName("row")[1].style.display="none";document.getElementsByClassName("row")[2].style.display="none";document.getElementsByClassName("col-xs-12")[3].style.display="none";document.getElementsByClassName("ng-scope")[6].style.display="none";document.getElementsByClassName("row password-reset")[0].style.display="none";');
                      final gotCookies = await cookieManager.getCookies(_url);
                      for (var item in gotCookies) {
                        var currentURL = await controller.currentUrl();
                        if (currentURL.startsWith("https://friends.youids.com")) {
                          break;
                        }
                        var x = item.toString().contains("sp_dc");
                        if (x == true) {
                          //setState(() => isVisible = false);
                          //controller.evaluateJavascript(
                          //'document.getElementsByClassName("user-details ng-binding")[0].innerHTML = "Başarıyla giriş yaptın! Arkadaşlarının aktivitelerini görmek için sağ üstteki profil simgesine tıklayabilirsin!"');
                          var myStr = item.toString();
                          var data;
                          data = myStr.split("=")[1].toString().split(";")[0];
                          spToken = data;
                          tokenOK = true;
                          break;
                        }
                      }

                      var currentURL = await controller.currentUrl();
                      if (currentURL == "https://accounts.spotify.com/tr/status" && tokenOK == true) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setString('token', spToken);
                        controller.evaluateJavascript("document.body.innerHTML = '';");
                        //setState(() => isVisible = false);
                        setState(() => myTitle = "Arkadaş Aktiviten");
                        controller.loadUrl("https://friends.youids.com/friendactivity.php?token=$spToken&location=$a");
                      }
                    })),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              //document.getElementById("login-button").click()
              var currentURL = await controller.currentUrl();
              if (currentURL == "https://accounts.spotify.com/tr/login") {
                controller.evaluateJavascript('document.getElementById("login-button").click()');
              } else {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                cookieManager.clearCookies();
                prefs.remove('token');
                //controller.clearCache();
                setState(() {
                  floaticon = Icon(Icons.logout);
                });
                setState(() {
                  controller.loadUrl("https://accounts.spotify.com/tr/login");
                  myTitle = "Spotify ile Oturum Aç";
                  controller.loadUrl(myURL);
                });
              }
            },
            child: floaticon,
            backgroundColor: Color(0xFF191414),
          ),
        ));
  }
}

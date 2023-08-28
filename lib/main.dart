import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import "package:flutter/services.dart" as service;
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void checkUpdates(context) async {
  if (Platform.isAndroid) {
    try {
      final response = await http.get(Uri.parse(
          'https://api.github.com/repos/Aytixel/licence_informatique_lemans_app/releases?per_page=1'));

      if (response.statusCode == 200) {
        final String checkVersion =
            jsonDecode(utf8.decode(response.bodyBytes))[0]['tag_name'];
        final String currentVersion = (loadYaml(
            await service.rootBundle.loadString('pubspec.yaml')))['version'];

        if (checkVersion != currentVersion) {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('Une nouvelle version est prête'),
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                  label: 'INSTALLER',
                  onPressed: () async {
                    scaffold.hideCurrentSnackBar();

                    final dio = Dio();
                    final Directory tempDir = await getTemporaryDirectory();
                    final String apkPath =
                        tempDir.path + '/licence-informatique-lemans.apk';

                    scaffold.showSnackBar(const SnackBar(
                        content: Text(
                            'Nouvelle version en cours de téléchargement, laissez l\'application ouverte')));

                    await dio.download(
                        'https://github.com/Aytixel/licence_informatique_lemans_app/releases/download/$checkVersion/app-release.apk',
                        apkPath);

                    if (response.statusCode == 200) {
                      OpenFile.open(apkPath);
                    }
                  }),
            ),
          );
        }
      }
    } catch (_) {}
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Licence Informatique LeMans',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color(0xff009c9a)),
        scaffoldBackgroundColor: const Color(0xFFD9D9D9),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    checkUpdates(context);

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://app.licence-informatique-lemans.tk/"));

    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'planning.dart';

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
        fontFamily: 'Louis George Cafe',
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
  final PageController _pageController = PageController(initialPage: 6);
  late Future<Planning> _futurePlanning;
  String _levelDropdownValue = 'l1';
  int _groupDropdownValue = 0;

  @override
  void initState() {
    super.initState();
    _initState();

    _futurePlanning = Planning.init(DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 6)),
        end: DateTime.now().add(const Duration(days: 7))));
  }

  void _initState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _levelDropdownValue = prefs.getString('level') ?? _levelDropdownValue;
      _groupDropdownValue = prefs.getInt('group') ?? _groupDropdownValue;
    });
  }

  void _reinit() {
    _futurePlanning = Planning.init(
        DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 6)),
            end: DateTime.now().add(const Duration(days: 7))),
        _levelDropdownValue,
        _groupDropdownValue);
    _futurePlanning.then((value) => _pageController.jumpToPage(6));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff009c9a),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(
                'assets/icon/icon_dark.png',
                fit: BoxFit.cover,
              ),
            ),
            const Text('Planning'),
            const SizedBox(
              height: 60,
              width: 60,
            )
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<Planning>(
              future: _futurePlanning,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return PlanningWidget(
                      planning: snapshot.data!,
                      pageController: _pageController);
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E2E2E)));
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: Card(
              color: const Color(0xFF2E2E2E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton(
                      value: _levelDropdownValue,
                      dropdownColor: const Color(0xFF2E2E2E),
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _levelDropdownValue = newValue!;
                          _reinit();
                        });
                      },
                      items: <String>['L1', 'L2', 'L3']
                          .map((String value) => DropdownMenuItem(
                                value: value.toLowerCase(),
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList()),
                  const SizedBox(width: 20),
                  DropdownButton(
                      value: _groupDropdownValue,
                      dropdownColor: const Color(0xFF2E2E2E),
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (int? newValue) {
                        setState(() {
                          _groupDropdownValue = newValue!;
                          _reinit();
                        });
                      },
                      items: <int>[0, 1, 2, 3, 4, 5]
                          .map((int value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  'TPGr${(value + 1)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList()),
                  IconButton(
                    onPressed: () async {
                      (await _futurePlanning).fetch(const Duration(days: 0));

                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
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

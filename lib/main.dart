import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String dateToDateString(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

Future<Planning> fetchPlanning(
    DateTimeRange dateTimeRange, String level, int group) async {
  final response = await http.get(Uri.parse(
      'https://api.licence-informatique-lemans.tk/v1/planning.json?level=${level}&group=${group}&start=${dateToDateString(dateTimeRange.start)}&end=${dateToDateString(dateTimeRange.end)}'));

  if (response.statusCode == 200) {
    return Planning.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}

class Planning {
  final String level;
  final int group;
  final DateTime startDate;
  final DateTime endDate;
  final List<dynamic> cources;

  Planning({
    required this.level,
    required this.group,
    required this.startDate,
    required this.endDate,
    required this.cources,
  });

  factory Planning.fromJson(Map<String, dynamic> json) {
    return Planning(
        level: json['level'],
        group: json['group'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        cources:
            json['cources'].map((value) => Cource.fromJson(value)).toList());
  }
}

class Cource {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> resources;
  final List<String> comment;

  Cource({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.resources,
    required this.comment,
  });

  factory Cource.fromJson(Map<String, dynamic> json) {
    return Cource(
        title: json['title'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        resources: List<String>.from(json['resources']),
        comment: List<String>.from(json['comment']));
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
        primarySwatch: Colors.blue,
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
  late Future<Planning> futurePlanning;

  @override
  void initState() {
    super.initState();
    futurePlanning = fetchPlanning(
        DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 7))),
        'l1',
        2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: FutureBuilder<Planning>(
        future: futurePlanning,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!.cources[0].title);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
    ));
  }
}

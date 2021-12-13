import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String dateToDateString(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String dateToHourString(DateTime startDate, DateTime endDate) {
  return '${startDate.hour}:${startDate.minute} - ${endDate.hour}:${endDate.minute}';
}

Future<Planning> fetchPlanning(
    DateTimeRange dateTimeRange, String level, int group) async {
  final response = await http.get(Uri.parse(
      'https://api.licence-informatique-lemans.tk/v1/planning.json?level=$level&group=$group&start=${dateToDateString(dateTimeRange.start)}&end=${dateToDateString(dateTimeRange.end)}'));

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
  final List<Day> days;

  Planning({
    required this.level,
    required this.group,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory Planning.fromJson(Map<String, dynamic> json) {
    DateTime startDate = DateTime.parse(json['startDate']);
    DateTime endDate = DateTime.parse(json['endDate']);
    int dayCount = endDate.difference(startDate).inDays;
    List<Day> days = List.generate(
        dayCount,
        (index) =>
            Day(date: startDate.add(Duration(days: index)), cources: []));
    List<dynamic> cources =
        json['cources'].map((dynamic value) => Cource.fromJson(value)).toList();

    cources.sort(
        (courceA, courceB) => courceA.startDate.compareTo(courceB.startDate));

    for (Cource cource in cources) {
      for (int i = 0; i < dayCount; i++) {
        if (cource.startDate.day == days[i].date.day &&
            cource.startDate.month == days[i].date.month &&
            cource.startDate.year == days[i].date.year) {
          days[i].cources.add(cource);
        }
      }
    }

    return Planning(
        level: json['level'],
        group: json['group'],
        startDate: startDate,
        endDate: endDate,
        days: days);
  }
}

class Day {
  final DateTime date;
  final List<dynamic> cources;

  Day({
    required this.date,
    required this.cources,
  });
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
            //return Text(snapshot.data!.cources[0].title);

            List<Widget> cources =
                List.generate(snapshot.data!.days.length, (int index) {
              Day day = snapshot.data!.days[index];

              if (day.cources.isEmpty) return Column();

              Cource cource = day.cources[0];

              return Column(children: <Widget>[
                Text(cource.title),
                Column(
                    children: cource.resources
                        .map((String value) => Text(value))
                        .toList()),
                Column(
                    children: cource.comment
                        .map((String value) => Text(value))
                        .toList()),
                Text(dateToHourString(cource.startDate, cource.endDate))
              ]);
            });

            return ListView(
              children: cources,
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
    ));
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String dateToDateString(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String dateToFormatedDateString(DateTime dateTime) {
  List<String> weekday = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  return '${weekday[dateTime.weekday - 1]} ${dateToDateString(dateTime)}';
}

String dateToHourString(DateTime startDate, DateTime endDate) {
  return '${startDate.hour}:${startDate.minute} - ${endDate.hour}:${endDate.minute}';
}

Future<Planning> fetchPlanning(
    DateTimeRange dateTimeRange, String level, int group) async {
  final response = await http.get(Uri.parse(
      'https://api.licence-informatique-lemans.tk/v1/planning.json?level=$level&group=$group&start=${dateToDateString(dateTimeRange.start)}&end=${dateToDateString(dateTimeRange.end)}'));

  if (response.statusCode == 200) {
    return Planning.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  } else {
    throw Exception('Failed to load planning');
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
      days[cource.startDate.difference(startDate).inDays].cources.add(cource);
    }

    return Planning(
      level: json['level'],
      group: json['group'],
      startDate: startDate,
      endDate: endDate,
      days: days,
    );
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
      comment: List<String>.from(json['comment']),
    );
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
          scaffoldBackgroundColor: const Color(0xFFD9D9D9),
          fontFamily: 'Louis George Cafe'),
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
        0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Planning>(
        future: futurePlanning,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PlanningWidget(planning: snapshot.data!);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class PlanningWidget extends StatelessWidget {
  const PlanningWidget({Key? key, required this.planning}) : super(key: key);

  final Planning planning;

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    return Scrollbar(
      isAlwaysShown: true,
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: List.generate(planning.days.length,
            (int index) => DayWidget(day: planning.days[index])),
      ),
    );
  }
}

class DayWidget extends StatelessWidget {
  const DayWidget({Key? key, required this.day}) : super(key: key);

  final Day day;

  @override
  Widget build(BuildContext context) {
    final List<Widget> courceList = <Widget>[
      Card(
        color: const Color(0xFF2E2E2E),
        child: SizedBox(
          height: 50,
          child: Center(
              child: Text(
            dateToFormatedDateString(day.date),
            style: const TextStyle(color: Colors.white),
          )),
        ),
      ),
    ];

    for (Cource cource in day.cources) {
      courceList.add(CourceWidget(cource: cource));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      width: MediaQuery.of(context).size.width,
      child: Card(
        color: const Color(0xFF1C1C1C),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Container(
            padding: const EdgeInsets.all(5),
            child: ListView(
              children: courceList,
            ),
          ),
        ),
      ),
    );
  }
}

class CourceWidget extends StatelessWidget {
  const CourceWidget({Key? key, required this.cource}) : super(key: key);

  final Cource cource;

  @override
  Widget build(BuildContext context) {
    final List<Widget> subtitleList = [];

    if (cource.resources.isNotEmpty) {
      subtitleList.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: cource.resources
              .map((value) => Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
      ));
    }
    if (cource.comment.isNotEmpty) {
      subtitleList.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: cource.comment
              .map((value) => Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
      ));
    }

    subtitleList.add(Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        dateToHourString(cource.startDate, cource.endDate),
        style: const TextStyle(color: Colors.white),
      ),
    ));

    Color cardBackgroundColor = const Color(0xFF2E2E2E);

    if (RegExp(r'cour|cm|conférence métier', caseSensitive: false)
        .hasMatch(cource.title)) {
      cardBackgroundColor = const Color(0x8CB8870B);
    }
    if (RegExp(r'exam|qcm|contrôle continu', caseSensitive: false)
        .hasMatch(cource.title)) {
      cardBackgroundColor = const Color(0x8CDC143C);
    }
    if (RegExp(r'td|gr[ ]*[a-c]', caseSensitive: false)
        .hasMatch(cource.title)) {
      cardBackgroundColor = const Color(0x8C318B57);
    }
    if (RegExp(r'tp|gr[ ]*[1-6]', caseSensitive: false)
        .hasMatch(cource.title)) {
      cardBackgroundColor = const Color(0x8C008B8B);
    }

    return Card(
      color: cardBackgroundColor,
      child: ListTile(
        title: Text(
          cource.title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Column(
          children: subtitleList,
        ),
      ),
    );
  }
}

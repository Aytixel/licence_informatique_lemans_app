import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  return '${weekday[dateTime.weekday - 1]} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String dateToHourString(DateTime startDate, DateTime endDate) {
  return '${startDate.hour}:${startDate.minute} - ${endDate.hour}:${endDate.minute}';
}

class Planning {
  final String level;
  final int group;

  DateTime startDate;
  DateTime endDate;
  List<Day> days;

  Planning({
    required this.level,
    required this.group,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  static Future<Planning> init(DateTimeRange dateTimeRange,
      [String level = '', int group = -1]) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (level != '') {
      await prefs.setString('level', level);
    }
    if (group != -1) {
      await prefs.setInt('group', group);
    }

    Planning planning = Planning(
      level: prefs.getString('level') ?? 'l1',
      group: prefs.getInt('group') ?? 0,
      startDate: DateTime(dateTimeRange.start.year, dateTimeRange.start.month, dateTimeRange.start.day),
      endDate: DateTime(dateTimeRange.end.year, dateTimeRange.end.month, dateTimeRange.end.day),
      days: [],
    );

    if (await planning.fetch(const Duration(days: 0))) {
      return planning;
    } else {
      throw Exception('Failed to load planning');
    }
  }

  Future<bool> fetch(Duration duration) async {
    duration = Duration(days: duration.inDays);

    DateTime _startDate = duration.isNegative
        ? startDate.add(duration)
        : (duration.inDays == 0 ? startDate : endDate);
    DateTime _endDate = duration.isNegative
        ? startDate
        : (duration.inDays == 0 ? endDate : endDate.add(duration));

    if (duration.isNegative) {
      startDate = _startDate;
    } else {
      endDate = _endDate;
    }

    final response = await http.get(Uri.parse(
        'https://api.licence-informatique-lemans.tk/v1/planning.json?level=$level&group=$group&start=${dateToDateString(_startDate)}&end=${dateToDateString(_endDate)}'));

    if (response.statusCode == 200) {
      Map<String, dynamic> decodedJson =
          jsonDecode(utf8.decode(response.bodyBytes));
      List<Day> _days = List.generate(
          _endDate.difference(_startDate).inDays.abs(),
          (index) =>
              Day(date: _startDate.add(Duration(days: index)), courses: []));
      List<dynamic> courses = decodedJson['courses']
          .map((dynamic value) => Course.fromJson(value))
          .toList();

      courses.sort(
          (courseA, courseB) => courseA.startDate.compareTo(courseB.startDate));

      for (Course course in courses) {
        _days[course.startDate.difference(_startDate).inDays]
            .courses
            .add(course);
      }

      if (duration.isNegative) {
        _days.sort((dayA, dayB) => dayB.date.compareTo(dayA.date));
      }

      for (Day day in _days) {
        if (duration.isNegative) {
          days.insert(0, day);
        } else {
          days.add(day);
        }
      }

      return true;
    } else {
      return false;
    }
  }
}

class Day {
  final DateTime date;
  final List<dynamic> courses;

  Day({
    required this.date,
    required this.courses,
  });
}

class Course {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> resources;
  final List<String> comment;

  Course({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.resources,
    required this.comment,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
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
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 7))),
        _levelDropdownValue,
        _groupDropdownValue);
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
                  return PlanningWidget(planning: snapshot.data!);
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

class PlanningWidget extends StatefulWidget {
  const PlanningWidget({Key? key, required this.planning}) : super(key: key);

  final Planning planning;

  @override
  State<PlanningWidget> createState() => _PlanningWidgetState();
}

class _PlanningWidgetState extends State<PlanningWidget> {
  final PageController _pageController = PageController(initialPage: 6);

  bool isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      isAlwaysShown: true,
      child: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        children: List.generate(widget.planning.days.length,
            (int index) => DayWidget(day: widget.planning.days[index])),
        onPageChanged: (value) {
          if (!isLoading) {
            if (value == 2) {
              isLoading = true;

              widget.planning.fetch(const Duration(days: -7)).then((succed) {
                isLoading = false;

                if (succed) {
                  setState(() {
                    _pageController.jumpToPage(9);
                  });
                }
              });
            } else if (value == widget.planning.days.length - 3) {
              isLoading = true;

              widget.planning.fetch(const Duration(days: 7)).then((succed) {
                isLoading = false;

                if (succed) {
                  setState(() {
                    _pageController
                        .jumpToPage(widget.planning.days.length - 10);
                  });
                }
              });
            }
          }
        },
      ),
    );
  }
}

class DayWidget extends StatelessWidget {
  const DayWidget({Key? key, required this.day}) : super(key: key);

  final Day day;

  @override
  Widget build(BuildContext context) {
    final List<Widget> courseList = <Widget>[
      Card(
        color: const Color(0xFF2E2E2E),
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              dateToFormatedDateString(day.date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    ];

    for (Course course in day.courses) {
      courseList.add(CourseWidget(course: course));
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
              children: courseList,
            ),
          ),
        ),
      ),
    );
  }
}

class CourseWidget extends StatelessWidget {
  const CourseWidget({Key? key, required this.course}) : super(key: key);

  final Course course;

  @override
  Widget build(BuildContext context) {
    final List<Widget> subtitleList = [];

    if (course.resources.isNotEmpty) {
      subtitleList.add(Container(
        padding: const EdgeInsets.only(top: 13),
        child: Column(
          children: course.resources
              .map((String value) => Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
      ));
    }
    if (course.comment.isNotEmpty) {
      subtitleList.add(Container(
        padding: const EdgeInsets.only(top: 13),
        child: Column(
          children: course.comment
              .map((String value) => Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
      ));
    }

    subtitleList.add(Container(
      padding: const EdgeInsets.only(top: 13, bottom: 10),
      child: Text(
        dateToHourString(course.startDate, course.endDate),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ));

    Color cardBackgroundColor = const Color(0xFF2E2E2E);

    if (RegExp('cour|cm|conférence métier', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8CB8870B);
    } else if (RegExp('exam|qcm|contrôle continu', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8CDC143C);
    } else if (RegExp('td|gr[ ]*[a-c]', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8C318B57);
    } else if (RegExp('tp|gr[ ]*[1-6]', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8C008B8B);
    }

    return Card(
      color: cardBackgroundColor,
      child: ListTile(
        title: Text(
          course.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          children: subtitleList,
        ),
      ),
    );
  }
}

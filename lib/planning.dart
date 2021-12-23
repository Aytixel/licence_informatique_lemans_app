import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'day.dart';
import 'course.dart';

String dateToDateString(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
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
      startDate: DateTime(dateTimeRange.start.year, dateTimeRange.start.month,
          dateTimeRange.start.day),
      endDate: DateTime(dateTimeRange.end.year, dateTimeRange.end.month,
          dateTimeRange.end.day),
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

class PlanningWidget extends StatefulWidget {
  const PlanningWidget(
      {Key? key, required this.planning, required this.pageController})
      : super(key: key);

  final Planning planning;
  final PageController pageController;

  @override
  State<PlanningWidget> createState() => _PlanningWidgetState();
}

class _PlanningWidgetState extends State<PlanningWidget> {
  bool isLoading = false;

  @override
  void dispose() {
    widget.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      isAlwaysShown: true,
      child: PageView(
        controller: widget.pageController,
        scrollDirection: Axis.horizontal,
        children: List.generate(widget.planning.days.length,
            (int index) => DayWidget(day: widget.planning.days[index])),
        onPageChanged: (value) {
          if (!isLoading) {
            if (value == 2) {
              isLoading = true;

              widget.planning.fetch(const Duration(days: -7)).then((succeed) {
                isLoading = false;

                if (succeed) {
                  setState(() {
                    widget.pageController.jumpToPage(9);
                  });
                }
              });
            } else if (value == widget.planning.days.length - 3) {
              isLoading = true;

              widget.planning.fetch(const Duration(days: 7)).then((succeed) {
                isLoading = false;

                if (succeed) {
                  setState(() {
                    widget.pageController
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
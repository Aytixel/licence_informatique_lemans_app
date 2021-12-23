import 'package:flutter/material.dart';

import 'course.dart';

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

class Day {
  final DateTime date;
  final List<dynamic> courses;

  Day({
    required this.date,
    required this.courses,
  });
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
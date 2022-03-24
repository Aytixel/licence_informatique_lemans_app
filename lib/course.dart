import 'package:flutter/material.dart';

String dateToHourString(DateTime startDate, DateTime endDate) {
  return '${startDate.hour}:${startDate.minute} - ${endDate.hour}:${endDate.minute}';
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

    if (RegExp('exam|qcm|contrôle|partiel|soutenance', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8CDC143C);
    } else if (RegExp('cour|cm|conférence', caseSensitive: false)
        .hasMatch(course.title)) {
      cardBackgroundColor = const Color(0x8CB8870B);
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
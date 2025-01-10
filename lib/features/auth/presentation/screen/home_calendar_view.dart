import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/shared/controller/custom_bottom_navigation_controller.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:login_signup/shared/widgets/navigation_bar.dart';
// Ajusta esta importación

class HomeCalendarView extends GetView<CustomBottomNavigationController> {
  const HomeCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('diciembre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: DayView(
        controller: EventController(),
        eventTileBuilder: (date, events, boundry, start, end) {
          return Container();
        },
        fullDayEventBuilder: (events, date) {
          return Container();
        },
        backgroundColor: const Color(0xFF1A1A2E),
        showVerticalLine: false,
        showLiveTimeLineInAllDays: true,
        minDay: DateTime(1990),
        maxDay: DateTime(2050),
        initialDay: DateTime(2021),
        heightPerMinute: 1,
        eventArranger: const SideEventArranger(),
        onEventTap: (events, date) => print(events),
        onEventDoubleTap: (events, date) => print(events),
        onEventLongTap: (events, date) => print(events),
        onDateLongPress: (date) => print(date),
        startHour: 6,
        endHour: 21,
        dayTitleBuilder: DayHeader.hidden,
        keepScrollOffset: true,
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}

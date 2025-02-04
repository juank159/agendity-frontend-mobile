// import 'package:calendar_view/calendar_view.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/appointments/presentation/controllers/calendar_controller.dart';
// import 'package:login_signup/features/appointments/presentation/widgets/day_header_widget.dart';
// import 'package:login_signup/features/appointments/presentation/widgets/month_calendar_view.dart';
// import 'package:login_signup/features/appointments/presentation/widgets/time_range_selector.dart';
// import 'package:login_signup/shared/custom_drawer.dart';
// import 'package:login_signup/shared/widgets/navigation_bar.dart';

// class HomeCalendarView extends GetView<CalendarController> {
//   const HomeCalendarView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final calendarController = CalendarControllerProvider.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: GestureDetector(
//           onTap: controller.toggleMonthView,
//           child: Obx(() => Row(
//                 children: [
//                   Text(
//                     controller.currentMonth.value,
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                   AnimatedRotation(
//                     turns: controller.isMonthViewVisible.value ? 0.5 : 0,
//                     duration: const Duration(milliseconds: 300),
//                     child: const Icon(Icons.keyboard_arrow_down),
//                   ),
//                 ],
//               )),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_none),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today_outlined),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       drawer: const CustomDrawer(),
//       body: Column(
//         children: [
//           Obx(() => AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 height: controller.isMonthViewVisible.value ? 300 : 0,
//                 child: controller.isMonthViewVisible.value
//                     ? MonthCalendarView(
//                         selectedDate: controller.selectedDate.value,
//                         onDaySelected: controller.onDaySelected,
//                         onPreviousMonth: controller.previousMonth,
//                         onNextMonth: controller.nextMonth,
//                       )
//                     : const SizedBox(),
//               )),
//           TimeRangeSelector(
//             startTime: '9:00 a.m.',
//             endTime: '5:00 p.m.',
//             onTap: () {},
//           ),
//           const DayHeaderWidget(),
//           Expanded(
//             child: DayView(
//               key: controller.dayViewKey, // Añadir esta línea
//               controller: controller.eventController,
//               initialDay: controller.selectedDate.value,
//               onPageChange: (date, page) {
//                 print(
//                     'DayView onPageChange: fecha=${date.toString()}, página=$page');
//                 controller.onPageChanged(date);
//               },
//               startHour: 7,
//               endHour: 21,
//               showVerticalLine: false,
//               backgroundColor: Colors.white,
//               eventTileBuilder: (date, events, boundary, start, end) {
//                 return Container();
//               },
//               fullDayEventBuilder: (events, date) {
//                 return Container();
//               },
//               showLiveTimeLineInAllDays: true,
//               minDay: DateTime(1990),
//               maxDay: DateTime(2050),
//               heightPerMinute: 1,
//               timeLineBuilder: (date) {
//                 final hour = date.hour;
//                 final minute = date.minute;
//                 return Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Text(
//                     '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 12,
//                     ),
//                   ),
//                 );
//               },
//               hourIndicatorSettings: const HourIndicatorSettings(
//                 height: 1,
//                 color: Colors.grey,
//               ),
//               keepScrollOffset: true,
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: const CustomBottomNavigation(),
//       floatingActionButton: Obx(() => controller.isMonthViewVisible.value
//           ? const SizedBox()
//           : FloatingActionButton(
//               onPressed: () {},
//               child: const Icon(Icons.add),
//               backgroundColor: const Color(0xFF3F51B5),
//             )),
//     );
//   }
// }

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/calendar_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/day_header_widget.dart';
import 'package:login_signup/features/appointments/presentation/widgets/month_calendar_view.dart';
import 'package:login_signup/features/appointments/presentation/widgets/time_range_selector.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:login_signup/shared/widgets/navigation_bar.dart';

class HomeCalendarView extends GetView<CalendarController> {
  const HomeCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: GestureDetector(
      //     onTap: controller.toggleMonthView,
      //     child: Obx(() => Row(
      //           children: [
      //             Row(
      //               children: [
      //                 Text(
      //                   controller.currentMonth.value,
      //                   style: const TextStyle(fontSize: 20),
      //                 ),
      //                 AnimatedRotation(
      //                   turns: controller.isMonthViewVisible.value ? 0.5 : 0,
      //                   duration: const Duration(milliseconds: 300),
      //                   child: const Icon(Icons.keyboard_arrow_down),
      //                 ),
      //               ],
      //             ),
      //             Container(
      //               margin: const EdgeInsets.only(left: 4),
      //               padding: const EdgeInsets.all(8),
      //               decoration: BoxDecoration(
      //                 color: Theme.of(context).primaryColor.withOpacity(0.1),
      //                 shape: BoxShape.circle,
      //               ),
      //               child: Text(
      //                 controller.currentDay.value.toString(),
      //                 style: TextStyle(
      //                   fontSize: 16,
      //                   color: Theme.of(context).primaryColor,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //               ),
      //             ),
      //           ],
      //         )),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.notifications_none),
      //       onPressed: () {},
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.calendar_today_outlined),
      //       onPressed: () {},
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.more_vert),
      //       onPressed: () {},
      //     ),
      //   ],
      // ),

      appBar: AppBar(
        title: GestureDetector(
          onTap: controller.toggleMonthView,
          child: Obx(() => Row(
                children: [
                  Text(
                    controller.currentMonth.value,
                    style: const TextStyle(fontSize: 20),
                  ),
                  AnimatedRotation(
                    turns: controller.isMonthViewVisible.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              )),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () {},
              ),
              Positioned(
                top: 20,
                child: Obx(() => Text(
                      controller.currentDay.value.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: controller.isMonthViewVisible.value ? 300 : 0,
                child: controller.isMonthViewVisible.value
                    ? MonthCalendarView(
                        selectedDate: controller.selectedDate.value,
                        onDaySelected: controller.onDaySelected,
                        onPreviousMonth: controller.previousMonth,
                        onNextMonth: controller.nextMonth,
                      )
                    : const SizedBox(),
              )),
          TimeRangeSelector(
            startTime: '9:00 a.m.',
            endTime: '5:00 p.m.',
            onTap: () {},
          ),
          const DayHeaderWidget(),
          Expanded(
            child: DayView(
              key: controller.dayViewKey,
              controller: controller.eventController,
              initialDay: controller.selectedDate.value,
              onPageChange: (date, page) {
                print(
                    'DayView onPageChange: fecha=${date.toString()}, página=$page');
                controller.onPageChanged(date);
              },
              startHour: 7,
              endHour: 21,
              showVerticalLine: false,
              backgroundColor: Colors.white,
              eventTileBuilder: (date, events, boundary, start, end) {
                return Container();
              },
              fullDayEventBuilder: (events, date) {
                return Container();
              },
              showLiveTimeLineInAllDays: true,
              minDay: DateTime(1990),
              maxDay: DateTime(2050),
              heightPerMinute: 1,
              timeLineBuilder: (date) {
                final hour = date.hour;
                final minute = date.minute;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
              hourIndicatorSettings: const HourIndicatorSettings(
                height: 1,
                color: Colors.grey,
              ),
              dayTitleBuilder: (date) => const SizedBox.shrink(),
              keepScrollOffset: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
      floatingActionButton: Obx(() => controller.isMonthViewVisible.value
          ? const SizedBox()
          : FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFF3F51B5),
            )),
    );
  }
}

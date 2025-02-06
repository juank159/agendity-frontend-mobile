import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:get/get.dart';
import '../controllers/calendar_controller.dart';

// class AnimatedDayView extends StatefulWidget {
//   final Function(DateTime, int) onPageChanged;
//   final DateTime initialDay;

//   const AnimatedDayView({
//     super.key,
//     required this.onPageChanged,
//     required this.initialDay,
//   });

//   @override
//   State<AnimatedDayView> createState() => _AnimatedDayViewState();
// }

// class _AnimatedDayViewState extends State<AnimatedDayView>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   final CalendarController controller = Get.find<CalendarController>();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeOutCubic,
//       ),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (context, child) {
//         return FadeTransition(
//           opacity: _fadeAnimation,
//           child: DayView(
//             key: ValueKey(widget.initialDay.toString()),
//             controller: controller.eventController,
//             initialDay: widget.initialDay,
//             eventTileBuilder: (date, events, boundary, start, end) {
//               print('Construyendo tile para fecha: $date');
//               print('Eventos disponibles: ${events.length}');
//               // Verificar si hay eventos
//               if (events.isEmpty) return Container();

//               // Obtener el primer evento
//               final event = events.first;
//               return Container(
//                 decoration: BoxDecoration(
//                   color: event.color ?? Colors.blue,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 padding: const EdgeInsets.all(8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       event.title ?? '',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     if (event.description != null)
//                       Text(
//                         event.description!,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                   ],
//                 ),
//               );
//             },
//             fullDayEventBuilder: (events, date) {
//               return Container(); // Maneja eventos de día completo si los necesitas
//             },
//             backgroundColor: Colors.white,
//             showVerticalLine: false,
//             showLiveTimeLineInAllDays: true,
//             minDay: DateTime(1990),
//             maxDay: DateTime(2050),
//             heightPerMinute: 1,
//             startHour: 7,
//             endHour: 21,
//             pageTransitionDuration: const Duration(milliseconds: 400),
//             pageTransitionCurve: Curves.easeInOut,
//             onPageChange: widget.onPageChanged,
//             dayTitleBuilder: (date) => const SizedBox.shrink(),
//             timeLineBuilder: (date) {
//               final hour = date.hour;
//               final minute = date.minute;
//               return Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8),
//                 child: Text(
//                   '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 12,
//                   ),
//                 ),
//               );
//             },
//             hourIndicatorSettings: const HourIndicatorSettings(
//               height: 1,
//               color: Colors.grey,
//             ),
//             keepScrollOffset: true,
//           ),
//         );
//       },
//     );
//   }
// }

// animated_day_view.dart
// (imports se mantienen igual)

class AnimatedDayView extends StatefulWidget {
  final Function(DateTime, int) onPageChanged;
  final DateTime initialDay;

  const AnimatedDayView({
    super.key,
    required this.onPageChanged,
    required this.initialDay,
  });

  @override
  State<AnimatedDayView> createState() => _AnimatedDayViewState();
}

class _AnimatedDayViewState extends State<AnimatedDayView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final CalendarController controller = Get.find<CalendarController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: DayView(
            key: ValueKey(widget.initialDay.toString()),
            controller: controller.eventController,
            initialDay: widget.initialDay,
            eventTileBuilder: (date, events, boundary, start, end) {
              if (events.isEmpty) return Container();

              final event = events.first;
              return Container(
                decoration: BoxDecoration(
                  color: event.color ?? Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.description != null)
                      Text(
                        event.description!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            },
            backgroundColor: Colors.white,
            showVerticalLine: false,
            showLiveTimeLineInAllDays: true,
            minDay: DateTime(1990),
            maxDay: DateTime(2050),
            heightPerMinute: 0.7,
            startHour: 7,
            endHour: 21,
            pageTransitionDuration: const Duration(milliseconds: 400),
            pageTransitionCurve: Curves.easeInOut,
            onPageChange: widget.onPageChanged,
            dayTitleBuilder: (date) => const SizedBox.shrink(),
            timeLineBuilder: (date) {
              if (date.minute == 0 || date.minute == 30) {
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
              }
              return const SizedBox();
            },
            hourIndicatorSettings: const HourIndicatorSettings(
              height: 1,
              color: Colors.grey,
            ),
            keepScrollOffset: true,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';

class AnimatedDayView extends StatefulWidget {
  final Function(DateTime, int) onPageChanged;
  final DateTime initialDay;

  const AnimatedDayView({
    Key? key,
    required this.onPageChanged,
    required this.initialDay,
  }) : super(key: key);

  @override
  State<AnimatedDayView> createState() => _AnimatedDayViewState();
}

class _AnimatedDayViewState extends State<AnimatedDayView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
            initialDay: widget.initialDay,
            eventTileBuilder: (date, events, boundary, start, end) {
              return Container();
            },
            fullDayEventBuilder: (events, date) {
              return Container();
            },
            backgroundColor: Colors.white,
            showVerticalLine: false,
            showLiveTimeLineInAllDays: true,
            minDay: DateTime(1990),
            maxDay: DateTime(2050),
            heightPerMinute: 1,
            startHour: 7,
            endHour: 21,
            pageTransitionDuration: const Duration(milliseconds: 400),
            pageTransitionCurve: Curves.easeInOut,
            onPageChange: widget.onPageChanged,
            dayTitleBuilder: (date) => const SizedBox.shrink(),
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
            keepScrollOffset: true,
          ),
        );
      },
    );
  }
}

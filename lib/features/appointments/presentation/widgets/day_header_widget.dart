import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/calendar_controller.dart';

class DayHeaderWidget extends GetView<CalendarController> {
  const DayHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Text(
              controller.currentDay.value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              controller.currentDayName.value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ));
  }
}

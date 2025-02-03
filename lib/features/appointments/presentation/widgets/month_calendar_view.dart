import 'package:flutter/material.dart';

class MonthCalendarView extends StatelessWidget {
  final Function(DateTime) onDaySelected;
  final DateTime selectedDate;
  final Function() onPreviousMonth;
  final Function() onNextMonth;

  const MonthCalendarView({
    Key? key,
    required this.onDaySelected,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('L'),
                Text('M'),
                Text('M'),
                Text('J'),
                Text('V'),
                Text('S'),
                Text('D'),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Expanded(
            child: _buildMonthGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final DateTime firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    final int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final int firstWeekday = firstDayOfMonth.weekday;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          onPreviousMonth();
        } else if (details.primaryVelocity! < 0) {
          onNextMonth();
        }
      },
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.5,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final int displayIndex = index - (firstWeekday - 1);
          final bool isCurrentMonth =
              displayIndex >= 0 && displayIndex < daysInMonth;

          if (!isCurrentMonth) return const SizedBox();

          final int dayNumber = displayIndex + 1;
          final bool isSelected = dayNumber == selectedDate.day;

          return InkWell(
            onTap: () {
              onDaySelected(DateTime(
                selectedDate.year,
                selectedDate.month,
                dayNumber,
              ));
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF3F51B5) : null,
              ),
              child: Center(
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

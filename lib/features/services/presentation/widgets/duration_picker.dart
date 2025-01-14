// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class DurationPicker extends StatelessWidget {
//   final Rx<Duration> duration;
//   final Function(Duration) onChanged;

//   const DurationPicker({
//     required this.duration,
//     required this.onChanged,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(28),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Duración',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 250,
//               child: Obx(() => ListWheelScrollView.useDelegate(
//                     itemExtent: 50,
//                     perspective: 0.006,
//                     diameterRatio: 1.6,
//                     physics: const FixedExtentScrollPhysics(),
//                     onSelectedItemChanged: (index) {
//                       onChanged(Duration(minutes: (index + 1) * 5));
//                     },
//                     controller: FixedExtentScrollController(
//                       initialItem: (duration.value.inMinutes / 5).round() - 1,
//                     ),
//                     childDelegate: ListWheelChildBuilderDelegate(
//                       childCount: 72,
//                       builder: (context, index) {
//                         final minutes = (index + 1) * 5;
//                         final isSelected = duration.value.inMinutes == minutes;
//                         return Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? Colors.grey.shade200
//                                 : Colors.transparent,
//                           ),
//                           child: Center(
//                             child: Text(
//                               '$minutes Minutos',
//                               style: TextStyle(
//                                 fontSize: isSelected ? 22 : 16,
//                                 fontWeight: isSelected
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                                 color: isSelected
//                                     ? Colors.black
//                                     : Colors.grey[500],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   )),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Get.back(),
//                     child: const Text(
//                       'CANCELAR',
//                       style: TextStyle(
//                         color: Colors.deepPurple,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   TextButton(
//                     onPressed: () => Get.back(),
//                     child: const Text(
//                       'ACEPTAR',
//                       style: TextStyle(
//                         color: Colors.deepPurple,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DurationPicker extends StatelessWidget {
  final Rx<Duration> duration;
  final Function(Duration) onChanged;

  const DurationPicker({
    required this.duration,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Duración',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Obx(() => ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.006,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      onChanged(Duration(
                          minutes: (index + 1) * 15)); // Cambiado de 5 a 15
                    },
                    controller: FixedExtentScrollController(
                      initialItem: (duration.value.inMinutes / 15).round() -
                          1, // Cambiado de 5 a 15
                    ),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount:
                          24, // Ajustado para mantener el mismo rango total pero con intervalos de 15
                      builder: (context, index) {
                        final minutes = (index + 1) * 15; // Cambiado de 5 a 15
                        final isSelected = duration.value.inMinutes == minutes;

                        // Formatear el texto para mostrar horas cuando corresponda
                        String durationText;
                        if (minutes >= 60) {
                          final hours = minutes ~/ 60;
                          final remainingMinutes = minutes % 60;
                          if (remainingMinutes == 0) {
                            durationText =
                                '$hours ${hours == 1 ? 'Hora' : 'Horas'}';
                          } else {
                            durationText =
                                '$hours ${hours == 1 ? 'Hora' : 'Horas'} $remainingMinutes Minutos';
                          }
                        } else {
                          durationText = '$minutes Minutos';
                        }

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.grey.shade200
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              durationText,
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'ACEPTAR',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

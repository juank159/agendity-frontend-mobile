import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/edit_appointment_dialog.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/payments/presentation/widgets/payment_dialog.dart';

class AppointmentDetailsDialog extends StatelessWidget {
  final AppointmentEntity appointment;

  const AppointmentDetailsDialog({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Intentar obtener el controlador de empleados
    final employeesController = Get.find<EmployeesController>();

    final totalDuration = appointment.endTime.difference(appointment.startTime);
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final durationText = hours > 0
        ? '$hours h ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';

    // Determinar si la cita está pagada usando los métodos de la entidad
    final bool isPaid = appointment.isPaymentCompleted;

    // Color del encabezado según estado de pago
    final Color headerColor = isPaid
        ? appointment.getPaymentStatusColor()
        : appointment.getStatusColor();

    // Texto de estado según pago
    final String headerStatusText = isPaid
        ? appointment.getPaymentStatusText()
        : appointment.getStatusText();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con color según estado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.clientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenido principal
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fecha y hora
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              const Icon(Icons.access_time, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(appointment.startTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Row(
                              //   children: [
                              //     Text(
                              //       '${DateFormat('h:mm a').format(appointment.startTime.toLocal())} - '
                              //       '${DateFormat('h:mm a').format(appointment.endTime.toLocal())}',
                              //       style: TextStyle(
                              //         color: Colors.grey[600],
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8),
                              //     Container(
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 8, vertical: 2),
                              //       decoration: BoxDecoration(
                              //         color: Colors.grey[200],
                              //         borderRadius: BorderRadius.circular(12),
                              //       ),
                              //       child: Text(
                              //         durationText,
                              //         style: TextStyle(
                              //           fontSize: 12,
                              //           color: Colors.grey[700],
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${DateFormat('h:mm a').format(appointment.startTime.toLocal())} - '
                                      '${DateFormat('h:mm a').format(appointment.endTime.toLocal())}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      durationText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Profesional
                    if (appointment.professionalId != null &&
                        appointment.professionalId!.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profesional',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Mostrar el nombre del profesional con FutureBuilder
                                FutureBuilder<EmployeeEntity?>(
                                  future: employeesController.getEmployeeById(
                                      appointment.professionalId!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Row(
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cargando información...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else if (snapshot.hasError ||
                                        snapshot.data == null) {
                                      // También buscar en el empleado seleccionado actualmente
                                      final selectedEmployee =
                                          employeesController
                                              .selectedEmployee.value;
                                      if (selectedEmployee != null &&
                                          selectedEmployee.id ==
                                              appointment.professionalId) {
                                        return Text(
                                          '${selectedEmployee.name} ${selectedEmployee.lastname}'
                                              .trim(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }

                                      // Buscar en la lista de empleados cargados
                                      for (var employee
                                          in employeesController.employees) {
                                        if (employee.id ==
                                            appointment.professionalId) {
                                          return Text(
                                            '${employee.name} ${employee.lastname}'
                                                .trim(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        }
                                      }

                                      // Si todavía no encontramos, mostrar ID
                                      return Text(
                                        'Profesional ID: ${appointment.professionalId}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    } else {
                                      final employee = snapshot.data!;
                                      return Text(
                                        '${employee.name} ${employee.lastname}'
                                            .trim(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                    ],

                    // Servicios
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.spa, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Servicios',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...appointment.serviceTypes
                                  .map((service) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isPaid
                                                    ? Colors.green[700]
                                                    : appointment
                                                        .getPrimaryColor(),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(service)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Precio y estado de pago
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.attach_money,
                                  color: isPaid ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    '\$${appointment.totalPrice}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.green[700]
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Estatus de pago
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: appointment
                                .getPaymentStatusColor()
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: appointment
                                  .getPaymentStatusColor()
                                  .withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            appointment.getPaymentStatusText(),
                            style: TextStyle(
                              color: appointment.getPaymentStatusColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Notas (si existen)
                    if (appointment.notes?.isNotEmpty ?? false) ...[
                      const Divider(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.note, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botones de acción
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.end,
                    //   children: [
                    //     TextButton(
                    //       onPressed: () => Navigator.pop(context),
                    //       child: const Text('Cerrar'),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     ElevatedButton.icon(
                    //       onPressed: () {
                    //         // Acción para editar cita
                    //         Navigator.pop(context);
                    //       },
                    //       icon: const Icon(Icons.edit, size: 18),
                    //       label: const Text('Editar cita'),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: isPaid
                    //             ? Colors.green
                    //             : Theme.of(context).primaryColor,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    // Botones de acción
                    // Botones de acción
                    // Botones de acción
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Botón de cerrar siempre visible
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        ),

                        // Mostrar botones adicionales solo si no está pagado
                        if (!isPaid) ...[
                          const SizedBox(height: 8),

                          // Botón de registrar pago
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Cerrar el diálogo actual
                              Navigator.pop(context);

                              // Mostrar el diálogo de pago
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => PaymentDialog(
                                  appointment: appointment,
                                ),
                              );

// Si el pago se realizó correctamente
                              if (result == true) {
                                // Aquí puedes notificar a otros widgets o controladores que necesiten actualizarse
                                // Por ejemplo, podrías actualizar la lista de citas:
                                if (Get.isRegistered<
                                    AppointmentsController>()) {
                                  Get.find<AppointmentsController>()
                                      .fetchAppointments();
                                }
                              }
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Registrar pago'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Botón de editar
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Acción para editar cita
                              Navigator.pop(context);
                              // Conseguir el controlador de citas
                              final appointmentsController =
                                  Get.find<AppointmentsController>();

                              // Mostrar el diálogo de edición y esperar el resultado
                              final result = await EditAppointmentDialog.show(
                                context,
                                appointment,
                                appointmentsController,
                              );

                              if (result == true) {
                                appointmentsController.fetchAppointments();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar cita'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para formatear la fecha con primera letra mayúscula
  String _formatDate(DateTime date) {
    final dateStr =
        DateFormat('EEEE, dd MMMM yyyy', 'es').format(date.toLocal());
    if (dateStr.isNotEmpty) {
      return dateStr[0].toUpperCase() + dateStr.substring(1);
    }
    return dateStr;
  }
}

// Función auxiliar para mostrar el diálogo
void showAppointmentDetails(
    BuildContext context, AppointmentEntity appointment) {
  // Asegurarse de que el controlador de empleados esté disponible
  if (!Get.isRegistered<EmployeesController>()) {
    Get.snackbar(
      'Error',
      'No se pudo cargar la información del profesional',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  showDialog(
    context: context,
    builder: (context) => AppointmentDetailsDialog(
      appointment: appointment,
    ),
  );
}

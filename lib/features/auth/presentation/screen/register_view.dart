// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
// import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
// import 'package:login_signup/features/auth/presentation/widgets/input_global_form.dart';
// import 'package:login_signup/features/auth/presentation/widgets/social_media.dart';
// import 'package:login_signup/utils/global_colors.dart';

// class RegisterView extends GetView<RegisterController> {
//   const RegisterView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Obx(
//         () => SingleChildScrollView(
//           child: SafeArea(
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(15.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Logo
//                   Container(
//                     alignment: Alignment.center,
//                     child: SvgPicture.asset(
//                       'assets/images/logo.svg',
//                       height: 100,
//                       colorFilter: ColorFilter.mode(
//                         GlobalColors.mainColor,
//                         BlendMode.srcIn,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // Título
//                   Text(
//                     'Crear una cuenta',
//                     style: TextStyle(
//                       color: GlobalColors.textColor,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Completa tus datos para registrarte',
//                     style: TextStyle(
//                       color: GlobalColors.textColor.withOpacity(0.6),
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   // Campo Nombre
//                   InputGlobalForm(
//                     controller: controller.nameController,
//                     text: 'Nombre',
//                     obscureText: false,
//                     textInputType: TextInputType.text,
//                   ),
//                   // Error de nombre
//                   Obx(() => controller.nameError.value.isNotEmpty
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 4, left: 4),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error,
//                                   color: Colors.red, size: 16),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   controller.nameError.value,
//                                   style: const TextStyle(
//                                       color: Colors.red, fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox.shrink()),
//                   const SizedBox(height: 16),

//                   // Campo Apellido
//                   InputGlobalForm(
//                     controller: controller.lastnameController,
//                     text: 'Apellidos',
//                     obscureText: false,
//                     textInputType: TextInputType.text,
//                   ),
//                   // Error de apellido
//                   Obx(() => controller.lastnameError.value.isNotEmpty
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 4, left: 4),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error,
//                                   color: Colors.red, size: 16),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   controller.lastnameError.value,
//                                   style: const TextStyle(
//                                       color: Colors.red, fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox.shrink()),
//                   const SizedBox(height: 16),

//                   // Campo Teléfono
//                   InputGlobalForm(
//                     controller: controller.phoneController,
//                     text: 'Teléfono (10 dígitos)',
//                     obscureText: false,
//                     textInputType: TextInputType.number,
//                   ),
//                   // Error de teléfono
//                   Obx(() => controller.phoneError.value.isNotEmpty
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 4, left: 4),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error,
//                                   color: Colors.red, size: 16),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   controller.phoneError.value,
//                                   style: const TextStyle(
//                                       color: Colors.red, fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox.shrink()),
//                   const SizedBox(height: 16),

//                   // Campo Email
//                   InputGlobalForm(
//                     controller: controller.emailController,
//                     text: 'Correo electrónico',
//                     obscureText: false,
//                     textInputType: TextInputType.emailAddress,
//                   ),
//                   // Error de email
//                   Obx(() => controller.emailError.value.isNotEmpty
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 4, left: 4),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error,
//                                   color: Colors.red, size: 16),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   controller.emailError.value,
//                                   style: const TextStyle(
//                                       color: Colors.red, fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox.shrink()),
//                   const SizedBox(height: 16),

//                   // Campo Contraseña
//                   InputGlobalForm(
//                     controller: controller.passwordController,
//                     text: 'Contraseña',
//                     obscureText: !controller.isPasswordVisible.value,
//                     textInputType: TextInputType.text,
//                   ),

//                   // Botón mostrar/ocultar contraseña y validar
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       TextButton(
//                         onPressed: () => controller.validatePassword(),
//                         child: Text(
//                           'Validar contraseña',
//                           style: TextStyle(
//                             color: GlobalColors.mainColor,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: controller.togglePasswordVisibility,
//                         child: Text(
//                           controller.isPasswordVisible.value
//                               ? 'Ocultar'
//                               : 'Mostrar',
//                           style: TextStyle(
//                             color: GlobalColors.mainColor,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   // Error de contraseña
//                   Obx(() => controller.passwordError.value.isNotEmpty
//                       ? Padding(
//                           padding: const EdgeInsets.only(left: 4),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error,
//                                   color: Colors.red, size: 16),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   controller.passwordError.value,
//                                   style: const TextStyle(
//                                       color: Colors.red, fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox.shrink()),

//                   // Indicadores de validación de contraseña
//                   Obx(() {
//                     if (controller.passwordValidations.isEmpty) {
//                       return const SizedBox.shrink();
//                     }

//                     return Container(
//                       margin: const EdgeInsets.only(top: 12),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[200]!),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Requisitos de contraseña:',
//                             style: TextStyle(
//                               color: GlobalColors.textColor,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           _buildValidationItem(
//                               'Al menos 8 caracteres', 'length'),
//                           _buildValidationItem(
//                               'Una letra mayúscula', 'uppercase'),
//                           _buildValidationItem(
//                               'Una letra minúscula', 'lowercase'),
//                           _buildValidationItem('Un número', 'number'),
//                           _buildValidationItem(
//                               'Un carácter especial (@\$!%*?&)', 'special'),
//                         ],
//                       ),
//                     );
//                   }),

//                   const SizedBox(height: 24),

//                   // Botón de registro
//                   controller.isLoading.value
//                       ? const Center(
//                           child: CircularProgressIndicator(),
//                         )
//                       : ButtonGlobalForm(
//                           textButton: 'Crear cuenta',
//                           onPressed: controller.registerUser,
//                         ),

//                   const SizedBox(height: 30),

//                   // Redes sociales
//                   const SocialMedia(
//                     text: '- O Regístrate Con -',
//                   ),

//                   const SizedBox(height: 20),

//                   // Link para ir al login
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         '¿Ya tienes una cuenta? ',
//                         style: TextStyle(
//                           color: GlobalColors.textColor.withOpacity(0.6),
//                           fontSize: 14,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () => Get.back(),
//                         child: Text(
//                           'Inicia sesión',
//                           style: TextStyle(
//                             color: GlobalColors.mainColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildValidationItem(String text, String key) {
//     return Obx(() {
//       final isValid = controller.passwordValidations[key] ?? false;
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 2),
//         child: Row(
//           children: [
//             Icon(
//               controller.getValidationIcon(isValid),
//               size: 16,
//               color: controller.getValidationColor(isValid),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: controller.getValidationColor(isValid),
//                   fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }

// ============================================

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
// import '../../../../utils/global_colors.dart';

// class RegisterView extends GetView<RegisterController> {
//   const RegisterView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('🎨 RegisterView build() iniciado');

//     return Scaffold(
//       body: Container(
//         decoration: _buildBackgroundDecoration(),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 _buildHeader(),
//                 const SizedBox(height: 20),
//                 _buildTitle(),
//                 const SizedBox(height: 32),
//                 _buildTextField(
//                   label: 'Nombre',
//                   controller: controller.nameController,
//                   icon: Icons.person_outline,
//                   hintText: 'Tu nombre',
//                   errorObservable: controller.nameError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Apellidos',
//                   controller: controller.lastnameController,
//                   icon: Icons.person_outline,
//                   hintText: 'Tus apellidos',
//                   errorObservable: controller.lastnameError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Teléfono',
//                   controller: controller.phoneController,
//                   icon: Icons.phone_outlined,
//                   hintText: '3001234567',
//                   keyboardType: TextInputType.phone,
//                   errorObservable: controller.phoneError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Correo electrónico',
//                   controller: controller.emailController,
//                   icon: Icons.email_outlined,
//                   hintText: 'tu@email.com',
//                   keyboardType: TextInputType.emailAddress,
//                   errorObservable: controller.emailError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildPasswordField(),
//                 _buildPasswordValidateButton(),
//                 _buildPasswordError(),
//                 _buildPasswordValidationIndicators(),
//                 const SizedBox(height: 10),
//                 _buildRegisterButton(),
//                 const SizedBox(height: 24),
//                 _buildLoginLink(),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Decoración del fondo
//   BoxDecoration _buildBackgroundDecoration() {
//     return BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [
//           GlobalColors.mainColor.withOpacity(0.1),
//           Colors.white,
//           Colors.white,
//         ],
//       ),
//     );
//   }

//   // Header con logo
//   Widget _buildHeader() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: SvgPicture.asset(
//           'assets/images/logo.svg',
//           height: 60,
//           colorFilter: ColorFilter.mode(
//             GlobalColors.mainColor,
//             BlendMode.srcIn,
//           ),
//         ),
//       ),
//     );
//   }

//   // Título de la pantalla
//   Widget _buildTitle() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Crear una cuenta 🚀',
//           style: TextStyle(
//             color: GlobalColors.textColor,
//             fontSize: 26,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           'Completa tus datos para registrarte',
//           style: TextStyle(
//             color: GlobalColors.textColor.withOpacity(0.6),
//             fontSize: 15,
//           ),
//         ),
//       ],
//     );
//   }

//   // TextField con label flotante
//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     required String hintText,
//     required RxString errorObservable,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: _buildInputTextStyle(),
//           decoration: InputDecoration(
//             labelText: label, // Aquí está el cambio principal
//             labelStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.7),
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             floatingLabelStyle: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//             hintText: hintText,
//             hintStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.5),
//               fontSize: 16,
//             ),
//             prefixIcon: Icon(
//               icon,
//               color: GlobalColors.mainColor,
//               size: 22,
//             ),
//             filled: true,
//             fillColor: GlobalColors.mainColor.withOpacity(0.05),
//             border:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             enabledBorder:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
//             errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
//             focusedErrorBorder: _buildInputBorder(Colors.red, 2),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 20, // Aumentado para acomodar el label flotante
//             ),
//           ),
//         ),
//         _buildErrorMessage(errorObservable),
//       ],
//     );
//   }

//   // Campo de contraseña especial
//   Widget _buildPasswordField() {
//     return Obx(() => TextField(
//           controller: controller.passwordController,
//           obscureText: !controller.isPasswordVisible.value,
//           style: _buildInputTextStyle(),
//           decoration: InputDecoration(
//             labelText: 'Contraseña', // Label flotante
//             labelStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.7),
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             floatingLabelStyle: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//             hintText: 'Mínimo 8 caracteres',
//             hintStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.5),
//               fontSize: 16,
//             ),
//             prefixIcon: Icon(
//               Icons.lock_outline,
//               color: GlobalColors.mainColor,
//               size: 22,
//             ),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 controller.isPasswordVisible.value
//                     ? Icons.visibility_outlined
//                     : Icons.visibility_off_outlined,
//                 color: GlobalColors.mainColor,
//                 size: 22,
//               ),
//               onPressed: controller.togglePasswordVisibility,
//             ),
//             filled: true,
//             fillColor: GlobalColors.mainColor.withOpacity(0.05),
//             border:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             enabledBorder:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
//             errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
//             focusedErrorBorder: _buildInputBorder(Colors.red, 2),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 20,
//             ),
//           ),
//         ));
//   }

//   // Estilo de texto para inputs
//   TextStyle _buildInputTextStyle() {
//     return TextStyle(
//       color: GlobalColors.textColor,
//       fontSize: 16,
//     );
//   }

//   // Borde para inputs
//   OutlineInputBorder _buildInputBorder(Color color, double width) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide(color: color, width: width),
//     );
//   }

//   // Mensaje de error
//   Widget _buildErrorMessage(RxString errorObservable) {
//     return Obx(() => errorObservable.value.isNotEmpty
//         ? Padding(
//             padding: const EdgeInsets.only(top: 8, left: 16),
//             child: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 16),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     errorObservable.value,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : const SizedBox.shrink());
//   }

//   // Botón validar contraseña
//   Widget _buildPasswordValidateButton() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         TextButton(
//           onPressed: () {
//             debugPrint('🔍 Validando contraseña');
//             controller.validatePassword();
//           },
//           child: Text(
//             'Validar contraseña',
//             style: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Error de contraseña
//   Widget _buildPasswordError() {
//     return Obx(() => controller.passwordError.value.isNotEmpty
//         ? Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 16),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     controller.passwordError.value,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : const SizedBox.shrink());
//   }

//   // Indicadores de validación de contraseña
//   Widget _buildPasswordValidationIndicators() {
//     return Obx(() {
//       if (controller.passwordValidations.isEmpty) {
//         return const SizedBox.shrink();
//       }

//       return Container(
//         margin: const EdgeInsets.only(top: 16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: GlobalColors.mainColor.withOpacity(0.03),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: GlobalColors.mainColor.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Requisitos de contraseña:',
//               style: TextStyle(
//                 color: GlobalColors.textColor,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildValidationItem('Al menos 8 caracteres', 'length'),
//             _buildValidationItem('Una letra mayúscula', 'uppercase'),
//             _buildValidationItem('Una letra minúscula', 'lowercase'),
//             _buildValidationItem('Un número', 'number'),
//             _buildValidationItem('Un carácter especial (@\$!%*?&)', 'special'),
//           ],
//         ),
//       );
//     });
//   }

//   // Item de validación individual
//   Widget _buildValidationItem(String text, String key) {
//     return Obx(() {
//       final isValid = controller.passwordValidations[key] ?? false;
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 3),
//         child: Row(
//           children: [
//             Icon(
//               controller.getValidationIcon(isValid),
//               size: 16,
//               color: controller.getValidationColor(isValid),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: controller.getValidationColor(isValid),
//                   fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   // Botón de registro
//   Widget _buildRegisterButton() {
//     return Obx(() => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [
//                 GlobalColors.mainColor,
//                 GlobalColors.mainColor.withOpacity(0.8),
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: GlobalColors.mainColor.withOpacity(0.3),
//                 spreadRadius: 0,
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: ElevatedButton(
//             onPressed: controller.isLoading.value
//                 ? null
//                 : () {
//                     debugPrint('📝 Botón registro presionado');
//                     controller.registerUser();
//                   },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: controller.isLoading.value
//                 ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : const Text(
//                     'Crear cuenta',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//           ),
//         ));
//   }

//   // Link para ir al login
//   Widget _buildLoginLink() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           '¿Ya tienes una cuenta? ',
//           style: TextStyle(
//             color: GlobalColors.textColor.withOpacity(0.6),
//             fontSize: 14,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             debugPrint('🚀 Volviendo a login');
//             Get.back();
//           },
//           child: Text(
//             'Inicia sesión',
//             style: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ==================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
// import 'package:login_signup/features/auth/presentation/widgets/social_media.dart';
// import '../../../../utils/global_colors.dart';

// class RegisterView extends GetView<RegisterController> {
//   const RegisterView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('🎨 RegisterView build() iniciado');

//     return Scaffold(
//       body: Container(
//         decoration: _buildBackgroundDecoration(),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 _buildHeader(),
//                 const SizedBox(height: 20),
//                 _buildTitle(),
//                 const SizedBox(height: 32),
//                 _buildTextField(
//                   label: 'Nombre',
//                   controller: controller.nameController,
//                   icon: Icons.person_outline,
//                   hintText: 'Tu nombre',
//                   errorObservable: controller.nameError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Apellidos',
//                   controller: controller.lastnameController,
//                   icon: Icons.person_outline,
//                   hintText: 'Tus apellidos',
//                   errorObservable: controller.lastnameError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Teléfono',
//                   controller: controller.phoneController,
//                   icon: Icons.phone_outlined,
//                   hintText: '3001234567',
//                   keyboardType: TextInputType.phone,
//                   errorObservable: controller.phoneError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildTextField(
//                   label: 'Correo electrónico',
//                   controller: controller.emailController,
//                   icon: Icons.email_outlined,
//                   hintText: 'tu@email.com',
//                   keyboardType: TextInputType.emailAddress,
//                   errorObservable: controller.emailError,
//                 ),
//                 const SizedBox(height: 18),
//                 _buildPasswordField(),
//                 _buildPasswordValidateButton(),
//                 _buildPasswordError(),
//                 _buildPasswordValidationIndicators(),
//                 const SizedBox(height: 10),
//                 _buildRegisterButton(),
//                 const SizedBox(height: 32),
//                 // Widget de redes sociales
//                 const SocialMedia(text: 'O regístrate con'),
//                 const SizedBox(height: 24),
//                 _buildLoginLink(),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Decoración del fondo
//   BoxDecoration _buildBackgroundDecoration() {
//     return BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [
//           GlobalColors.mainColor.withOpacity(0.1),
//           Colors.white,
//           Colors.white,
//         ],
//       ),
//     );
//   }

//   // Header con logo
//   Widget _buildHeader() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: SvgPicture.asset(
//           'assets/images/logo.svg',
//           height: 60,
//           colorFilter: ColorFilter.mode(
//             GlobalColors.mainColor,
//             BlendMode.srcIn,
//           ),
//         ),
//       ),
//     );
//   }

//   // Título de la pantalla
//   Widget _buildTitle() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Crear una cuenta 🚀',
//           style: TextStyle(
//             color: GlobalColors.textColor,
//             fontSize: 26,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           'Completa tus datos para registrarte',
//           style: TextStyle(
//             color: GlobalColors.textColor.withOpacity(0.6),
//             fontSize: 15,
//           ),
//         ),
//       ],
//     );
//   }

//   // TextField con label flotante
//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     required String hintText,
//     required RxString errorObservable,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: _buildInputTextStyle(),
//           decoration: InputDecoration(
//             labelText: label,
//             labelStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.7),
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             floatingLabelStyle: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//             hintText: hintText,
//             hintStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.5),
//               fontSize: 16,
//             ),
//             prefixIcon: Icon(
//               icon,
//               color: GlobalColors.mainColor,
//               size: 22,
//             ),
//             filled: true,
//             fillColor: GlobalColors.mainColor.withOpacity(0.05),
//             border:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             enabledBorder:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
//             errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
//             focusedErrorBorder: _buildInputBorder(Colors.red, 2),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 20,
//             ),
//           ),
//         ),
//         _buildErrorMessage(errorObservable),
//       ],
//     );
//   }

//   // Campo de contraseña especial
//   Widget _buildPasswordField() {
//     return Obx(() => TextField(
//           controller: controller.passwordController,
//           obscureText: !controller.isPasswordVisible.value,
//           style: _buildInputTextStyle(),
//           decoration: InputDecoration(
//             labelText: 'Contraseña',
//             labelStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.7),
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             floatingLabelStyle: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//             hintText: 'Mínimo 8 caracteres',
//             hintStyle: TextStyle(
//               color: GlobalColors.textColor.withOpacity(0.5),
//               fontSize: 16,
//             ),
//             prefixIcon: Icon(
//               Icons.lock_outline,
//               color: GlobalColors.mainColor,
//               size: 22,
//             ),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 controller.isPasswordVisible.value
//                     ? Icons.visibility_outlined
//                     : Icons.visibility_off_outlined,
//                 color: GlobalColors.mainColor,
//                 size: 22,
//               ),
//               onPressed: controller.togglePasswordVisibility,
//             ),
//             filled: true,
//             fillColor: GlobalColors.mainColor.withOpacity(0.05),
//             border:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             enabledBorder:
//                 _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
//             focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
//             errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
//             focusedErrorBorder: _buildInputBorder(Colors.red, 2),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 20,
//             ),
//           ),
//         ));
//   }

//   // Estilo de texto para inputs
//   TextStyle _buildInputTextStyle() {
//     return TextStyle(
//       color: GlobalColors.textColor,
//       fontSize: 16,
//     );
//   }

//   // Borde para inputs
//   OutlineInputBorder _buildInputBorder(Color color, double width) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide(color: color, width: width),
//     );
//   }

//   // Mensaje de error
//   Widget _buildErrorMessage(RxString errorObservable) {
//     return Obx(() => errorObservable.value.isNotEmpty
//         ? Padding(
//             padding: const EdgeInsets.only(top: 8, left: 16),
//             child: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 16),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     errorObservable.value,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : const SizedBox.shrink());
//   }

//   // Botón validar contraseña
//   Widget _buildPasswordValidateButton() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         TextButton(
//           onPressed: () {
//             debugPrint('🔍 Validando contraseña');
//             controller.validatePassword();
//           },
//           child: Text(
//             'Validar contraseña',
//             style: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Error de contraseña
//   Widget _buildPasswordError() {
//     return Obx(() => controller.passwordError.value.isNotEmpty
//         ? Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 16),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     controller.passwordError.value,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : const SizedBox.shrink());
//   }

//   // Indicadores de validación de contraseña
//   Widget _buildPasswordValidationIndicators() {
//     return Obx(() {
//       if (controller.passwordValidations.isEmpty) {
//         return const SizedBox.shrink();
//       }

//       return Container(
//         margin: const EdgeInsets.only(top: 16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: GlobalColors.mainColor.withOpacity(0.03),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: GlobalColors.mainColor.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Requisitos de contraseña:',
//               style: TextStyle(
//                 color: GlobalColors.textColor,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildValidationItem('Al menos 8 caracteres', 'length'),
//             _buildValidationItem('Una letra mayúscula', 'uppercase'),
//             _buildValidationItem('Una letra minúscula', 'lowercase'),
//             _buildValidationItem('Un número', 'number'),
//             _buildValidationItem('Un carácter especial (@\$!%*?&)', 'special'),
//           ],
//         ),
//       );
//     });
//   }

//   // Item de validación individual
//   Widget _buildValidationItem(String text, String key) {
//     return Obx(() {
//       final isValid = controller.passwordValidations[key] ?? false;
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 3),
//         child: Row(
//           children: [
//             Icon(
//               controller.getValidationIcon(isValid),
//               size: 16,
//               color: controller.getValidationColor(isValid),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: controller.getValidationColor(isValid),
//                   fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   // Botón de registro
//   Widget _buildRegisterButton() {
//     return Obx(() => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [
//                 GlobalColors.mainColor,
//                 GlobalColors.mainColor.withOpacity(0.8),
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: GlobalColors.mainColor.withOpacity(0.3),
//                 spreadRadius: 0,
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: ElevatedButton(
//             onPressed: controller.isLoading.value
//                 ? null
//                 : () {
//                     debugPrint('📝 Botón registro presionado');
//                     controller.registerUser();
//                   },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: controller.isLoading.value
//                 ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : const Text(
//                     'Crear cuenta',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//           ),
//         ));
//   }

//   // Link para ir al login
//   Widget _buildLoginLink() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           '¿Ya tienes una cuenta? ',
//           style: TextStyle(
//             color: GlobalColors.textColor.withOpacity(0.6),
//             fontSize: 14,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             debugPrint('🚀 Volviendo a login');
//             Get.back();
//           },
//           child: Text(
//             'Inicia sesión',
//             style: TextStyle(
//               color: GlobalColors.mainColor,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/social_media.dart';
import '../../../../utils/global_colors.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 RegisterView build() iniciado');

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 10),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Nombre',
                  controller: controller.nameController,
                  icon: Icons.person_outline,
                  hintText: 'Tu nombre',
                  errorObservable: controller.nameError,
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  label: 'Apellidos',
                  controller: controller.lastnameController,
                  icon: Icons.person_outline,
                  hintText: 'Tus apellidos',
                  errorObservable: controller.lastnameError,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Teléfono',
                  controller: controller.phoneController,
                  icon: Icons.phone_outlined,
                  hintText: '3001234567',
                  keyboardType: TextInputType.phone,
                  errorObservable: controller.phoneError,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Correo electrónico',
                  controller: controller.emailController,
                  icon: Icons.email_outlined,
                  hintText: 'tu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  errorObservable: controller.emailError,
                ),
                const SizedBox(height: 12),
                _buildPasswordField(),
                _buildPasswordValidateButton(),
                _buildPasswordError(),
                _buildPasswordValidationIndicators(),
                const SizedBox(height: 6),
                _buildRegisterButton(),
                const SizedBox(height: 16),
                // Widget de redes sociales
                const SocialMedia(text: 'O regístrate con'),
                const SizedBox(height: 12),
                _buildLoginLink(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decoración del fondo
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GlobalColors.mainColor.withOpacity(0.1),
          Colors.white,
          Colors.white,
        ],
      ),
    );
  }

  // Header con logo
  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 85,
          colorFilter: ColorFilter.mode(
            GlobalColors.mainColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // Título de la pantalla
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crear una cuenta 🚀',
          style: TextStyle(
            color: GlobalColors.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Completa tus datos para registrarte',
          style: TextStyle(
            color: GlobalColors.textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // TextField con label flotante
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required RxString errorObservable,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: _buildInputTextStyle(),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              icon,
              color: GlobalColors.mainColor,
              size: 22,
            ),
            filled: true,
            fillColor: GlobalColors.mainColor.withOpacity(0.05),
            border:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            enabledBorder:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
            errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
            focusedErrorBorder: _buildInputBorder(Colors.red, 2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        _buildErrorMessage(errorObservable),
      ],
    );
  }

  // Campo de contraseña especial
  Widget _buildPasswordField() {
    return Obx(() => TextField(
          controller: controller.passwordController,
          obscureText: !controller.isPasswordVisible.value,
          style: _buildInputTextStyle(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            hintText: 'Mínimo 8 caracteres',
            hintStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: GlobalColors.mainColor,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: GlobalColors.mainColor,
                size: 22,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
            filled: true,
            fillColor: GlobalColors.mainColor.withOpacity(0.05),
            border:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            enabledBorder:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
            errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
            focusedErrorBorder: _buildInputBorder(Colors.red, 2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ));
  }

  // Estilo de texto para inputs
  TextStyle _buildInputTextStyle() {
    return TextStyle(
      color: GlobalColors.textColor,
      fontSize: 15,
    );
  }

  // Borde para inputs
  OutlineInputBorder _buildInputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Mensaje de error
  Widget _buildErrorMessage(RxString errorObservable) {
    return Obx(() => errorObservable.value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorObservable.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Botón validar contraseña
  Widget _buildPasswordValidateButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            debugPrint('🔍 Validando contraseña');
            controller.validatePassword();
          },
          child: Text(
            'Validar contraseña',
            style: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Error de contraseña
  Widget _buildPasswordError() {
    return Obx(() => controller.passwordError.value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    controller.passwordError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Indicadores de validación de contraseña
  Widget _buildPasswordValidationIndicators() {
    return Obx(() {
      if (controller.passwordValidations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlobalColors.mainColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GlobalColors.mainColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos de contraseña:',
              style: TextStyle(
                color: GlobalColors.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildValidationItem('Al menos 8 caracteres', 'length'),
            _buildValidationItem('Una letra mayúscula', 'uppercase'),
            _buildValidationItem('Una letra minúscula', 'lowercase'),
            _buildValidationItem('Un número', 'number'),
            _buildValidationItem('Un carácter especial (@\$!%*?&)', 'special'),
          ],
        ),
      );
    });
  }

  // Item de validación individual
  Widget _buildValidationItem(String text, String key) {
    return Obx(() {
      final isValid = controller.passwordValidations[key] ?? false;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              controller.getValidationIcon(isValid),
              size: 16,
              color: controller.getValidationColor(isValid),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: controller.getValidationColor(isValid),
                  fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Botón de registro
  Widget _buildRegisterButton() {
    return Obx(() => Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                GlobalColors.mainColor,
                GlobalColors.mainColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GlobalColors.mainColor.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () {
                    debugPrint('📝 Botón registro presionado');
                    controller.registerUser();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  // Link para ir al login
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: TextStyle(
            color: GlobalColors.textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            debugPrint('🚀 Volviendo a login');
            Get.back();
          },
          child: Text(
            'Inicia sesión',
            style: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

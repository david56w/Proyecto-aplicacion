import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> inicializarNotificaciones() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'travelx_misiones_channel', 
        'Notificaciones Importantes',
        description: 'Canal para alertas de misiones y amigos',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    debugPrint('✨ Sistema de notificaciones locales inicializado correctamente.');
  }

  static void escucharEventosEnTiempoReal() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('🚨 No hay usuario autenticado para escuchar notificaciones.');
      return;
    }

    debugPrint('🛰️ Encendiendo antenas de Realtime para el usuario: $uid');

    final canalAmistades = _supabase.channel('realtime:amistades');
    
    canalAmistades.onPostgresChanges(
      event: PostgresChangeEvent.insert, 
      schema: 'public',
      table: 'amistades', 
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id', 
        value: uid,
      ),
      callback: (payload) {
        debugPrint('🔥 ¡EVENTO DE AMISTAD DETECTADO EN REALTIME!');
        mostrarNotificacionLocal(
          id: DateTime.now().millisecond,
          titulo: '🤝 Nueva solicitud de amistad',
          body: '¡Alguien te ha enviado una solicitud! Revisa tu pestaña de amigos.',
        );
      },
    ).subscribe((status, error) {
      debugPrint('📡 [SOCKET AMISTADES STATUS]: $status');
      if (error != null) {
        debugPrint('❌ Error en canal de amistades: ${error.toString()}'); 
      }
    });

    final canalMisiones = _supabase.channel('realtime:misiones');
    
    canalMisiones.onPostgresChanges(
      event: PostgresChangeEvent.update, 
      schema: 'public',
      table: 'misiones',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id_usuario', 
        value: uid,
      ),
      callback: (payload) {
        final datosNuevos = payload.newRecord;
        debugPrint('🔥 ¡EVENTO DE MISIÓN DETECTADO EN BD! Datos: $datosNuevos');
        
        try {
          if (datosNuevos['fecha_expiracion'] != null) {
            final fechaExpiracion = DateTime.parse(datosNuevos['fecha_expiracion'].toString());
            final momentoAlerta = fechaExpiracion.subtract(const Duration(hours: 1));
            final nombreMision = datosNuevos['nombre']?.toString() ?? 'Misión Especial';
            final int notificationId = (datosNuevos['id']?.toString() ?? '0').hashCode;

            mostrarNotificacionLocal(
              id: notificationId + 1,
              titulo: '⚡ Cambio en misión detectado',
              body: 'La misión "$nombreMision" se ha actualizado correctamente.',
            );

            if (momentoAlerta.isAfter(DateTime.now())) {
              debugPrint('📅 Agendando alerta de expiración para: $momentoAlerta');
              programarNotificacionMision(
                id: notificationId,
                titulo: '⏰ ¡Misión por expirar pronto!',
                body: 'La misión "$nombreMision" vence en una hora. ¡Date prisa!',
                fechaProgramada: momentoAlerta,
              );
            } else {
              debugPrint('⚠️ No se agendó la alerta porque el tiempo calculado ya pasó.');
            }
          }
        } catch (e) {
          debugPrint('❌ Error al procesar datos de la misión: $e');
        }
      },
    ).subscribe((status, error) {
      debugPrint('📡 [SOCKET MISIONES STATUS]: $status');
      if (error != null) {
        debugPrint('❌ Error en canal de misiones: ${error.toString()}');
      }
    });
  }

  static void mostrarNotificacionLocal({required int id, required String titulo, required String body}) {
    debugPrint('📣 Intentando mostrar notificación visual local inmediata...');
    _localNotifications.show(
      id,
      titulo,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'travelx_misiones_channel',
          'Notificaciones Importantes',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
    );
  }

  static void programarNotificacionMision({
    required int id, 
    required String titulo, 
    required String body, 
    required DateTime fechaProgramada
  }) async {
    debugPrint('📅 Notificación agendada localmente para: $fechaProgramada');
    
    await _localNotifications.zonedSchedule(
      id,
      titulo,
      body,
      tz.TZDateTime.from(fechaProgramada, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'travelx_misiones_channel',
          'Notificaciones Importantes',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> apagarAntenasEnTiempoReal() async {
    debugPrint('🛑 Apagando antenas de Realtime...');
    try {
      await _supabase.removeAllChannels();
      debugPrint('✨ Todos los canales de Realtime fueron removidos con éxito.');
    } catch (e) {
      debugPrint('⚠️ Error al apagar canales: $e');
    }
  }
}
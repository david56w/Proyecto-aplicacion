import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> inicializarNotificaciones() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('¡Permiso de notificaciones concedido por el usuario!');
      
      String? token = await _messaging.getToken();
      debugPrint('FCM Token del dispositivo: $token');
      
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          mostrarNotificacionLocal(
            id: notification.hashCode,
            titulo: notification.title ?? '',
            body: notification.body ?? '',
          );
        }
      });
    } else {
      debugPrint('El usuario denegó el permiso de notificaciones.');
    }
  }

  static void escucharEventosEnTiempoReal() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('No hay usuario autenticado para escuchar notificaciones.');
      return;
    }

    debugPrint('Encendiendo antenas de Realtime para el usuario: $uid');

    _supabase
        .channel('realtime:amistades')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, 
          schema: 'public',
          table: 'amistades', 
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id', 
            value: uid,
          ),
          callback: (payload) {
            mostrarNotificacionLocal(
              id: DateTime.now().millisecond,
              titulo: '🤝 Nueva solicitud de amistad',
              body: '¡Alguien te ha enviado una solicitud! Revisa tu pestaña de amigos.',
            );
          },
        )
        .subscribe();

    _supabase
        .channel('realtime:misiones')
        .onPostgresChanges(
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
            
            if (datosNuevos['estado'] == 'por_expirar') {
              mostrarNotificacionLocal(
                id: datosNuevos['id'].hashCode,
                titulo: '⏰ ¡Misión por expirar!',
                body: 'La misión "${datosNuevos['nombre']}" está a punto de vencer. ¡Date prisa!',
              );
            }
          },
        )
        .subscribe();
  }

  static void mostrarNotificacionLocal({required int id, required String titulo, required String body}) {
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
        ),
      ),
    );
  }
}
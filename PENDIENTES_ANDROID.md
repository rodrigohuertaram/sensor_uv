# Pendientes para la app nativa de Android — Sensor UV

La app instalada desde Chrome ("Agregar a inicio") es la misma que la página web y recibe
todos los cambios automáticamente. Esta lista es para la **app nativa de Android** (APK),
que funcionará en segundo plano: aquí se anota todo lo que en la versión web funciona
gracias al navegador y que en la app nativa hay que hacer de otra forma.

Lo más reciente va arriba. Cada punto indica la fecha en que se anotó.

---

## Funcionar en segundo plano *(anotado 2026-10-05)*
En la web, Chrome congela la app en segundo plano o con la pantalla apagada. Como solución
parcial, la versión web: recuerda "UV de tu zona", actualiza el clima al volver si pasaron
15 minutos, cuenta el tiempo real que pasó y ofrece "Mantener la pantalla encendida".
En la app nativa hay que hacerlo de verdad:
- [ ] Actualizar la ubicación y el clima cada 15 minutos aunque la app esté en segundo plano o la pantalla apagada (servicio en primer plano con notificación fija, como hacen las apps de ejercicio).
- [ ] Equivalente de "Mantener la pantalla encendida" (por ejemplo, el paquete `wakelock_plus`), aunque con el servicio en primer plano ya no haría falta.
- [ ] Guardar las preferencias ("UV de tu zona", pantalla encendida) en el teléfono.

## Ubicación y clima *(anotado 2026-10-05)*
- [ ] Obtener la ubicación con un paquete nativo (por ejemplo `geolocator`); hoy `lib/ubicacion_stub.dart` solo muestra un aviso.
- [ ] Pedir el permiso de ubicación aproximada (`ACCESS_COARSE_LOCATION`) con una explicación clara.
- [ ] Agregar el permiso de internet (`INTERNET`) en `android/app/src/main/AndroidManifest.xml` para consultar Open-Meteo.
- [ ] Actualizar la ubicación y el clima también con la app en segundo plano (en la web se pausa cuando la pantalla se apaga).
- [ ] Recordar si el usuario activó "Usar el índice UV de tu zona" al volver a abrir la app.

## Guardado de datos *(anotado 2026-10-05)*
- [ ] Guardar los perfiles en el teléfono (por ejemplo con `shared_preferences`); hoy `lib/almacen_stub.dart` solo los recuerda mientras la app está abierta.

## Avisos en segundo plano *(anotado 2026-10-04)*
- [ ] Seguir contando la exposición al sol con la pantalla apagada (servicio en primer plano).
- [ ] Notificaciones de "Hora de reaplicar" aunque la app esté cerrada.

## Conexión con el dispositivo *(anotado 2026-10-04)*
- [ ] Bluetooth de bajo consumo con un paquete nativo (por ejemplo `flutter_blue_plus`) y sus permisos (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`).
- [ ] Mantener la conexión con la pantalla apagada y reconectar sola.
- [ ] Sincronizar el botón "Ya me reapliqué" en ambos sentidos (dispositivo ↔ app).

## Apariencia e instalación *(anotado 2026-10-05)*
- [ ] Icono de la app con el nuevo logo (hoy el APK usaría el icono genérico de Flutter).
- [ ] Nombre visible "Sensor UV" en el teléfono (hoy dice `sensor_uv`).
- [ ] Compilar el APK en GitHub Actions y publicarlo para descargar (así no hace falta activar el Modo de programador de Windows).

## Ya funciona igual en la app nativa (no requiere trabajo)
- Diseño adaptable, colores y logo dentro de la app.
- Aviso médico, test de tipo de piel, ayuda del FPS y selector de lugar y cielo.

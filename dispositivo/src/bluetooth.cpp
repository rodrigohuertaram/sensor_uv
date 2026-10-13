#include "bluetooth.h"

#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <Protocolo.h>

namespace bluetooth {

namespace {
BLEServer *servidor = nullptr;
BLECharacteristic *chConfiguracion = nullptr;
BLECharacteristic *chEstado = nullptr;
BLECharacteristic *chOrdenes = nullptr;

volatile bool hayConexion = false;

// Lo recibido se guarda aquí (lo escribe la tarea del Bluetooth y lo lee el loop)
portMUX_TYPE candado = portMUX_INITIALIZER_UNLOCKED;
Recibido pendiente;
bool hayPendiente = false;

class AlConectar : public BLEServerCallbacks {
  void onConnect(BLEServer *) override { hayConexion = true; }
  void onDisconnect(BLEServer *) override {
    hayConexion = false;
    BLEDevice::startAdvertising();  // volver a anunciarse para que la app se reconecte
  }
};

class AlEscribirConfiguracion : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    String valor = c->getValue();
    portENTER_CRITICAL(&candado);
    strlcpy(pendiente.configuracion, valor.c_str(), sizeof(pendiente.configuracion));
    pendiente.hayConfiguracion = true;
    hayPendiente = true;
    portEXIT_CRITICAL(&candado);
  }
};

class AlEscribirOrden : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    String valor = c->getValue();
    valor.trim();
    portENTER_CRITICAL(&candado);
    if (valor == protocolo::kOrdenReaplicado) pendiente.reaplicado = true;
    else if (valor == protocolo::kOrdenSilenciar) pendiente.silenciar = true;
    else if (valor == protocolo::kOrdenDormir) pendiente.dormir = true;
    hayPendiente = true;
    portEXIT_CRITICAL(&candado);
  }
};
}  // namespace

void iniciar() {
  BLEDevice::init(protocolo::kNombreDispositivo);
  servidor = BLEDevice::createServer();
  servidor->setCallbacks(new AlConectar());

  BLEService *servicio = servidor->createService(protocolo::kServicio);

  chConfiguracion = servicio->createCharacteristic(
      protocolo::kConfiguracion, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  chConfiguracion->setCallbacks(new AlEscribirConfiguracion());

  chEstado = servicio->createCharacteristic(
      protocolo::kEstado, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  chEstado->addDescriptor(new BLE2902());

  chOrdenes = servicio->createCharacteristic(
      protocolo::kOrdenes, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);
  chOrdenes->addDescriptor(new BLE2902());
  chOrdenes->setCallbacks(new AlEscribirOrden());

  servicio->start();

  BLEAdvertising *anuncio = BLEDevice::getAdvertising();
  anuncio->addServiceUUID(protocolo::kServicio);
  anuncio->setScanResponse(true);
  BLEDevice::startAdvertising();
}

bool conectado() { return hayConexion; }

bool tomarRecibido(Recibido &r) {
  if (!hayPendiente) return false;
  portENTER_CRITICAL(&candado);
  r = pendiente;
  pendiente = Recibido();
  hayPendiente = false;
  portEXIT_CRITICAL(&candado);
  return true;
}

void publicarEstado(const char *texto) {
  if (chEstado == nullptr) return;
  chEstado->setValue(texto);
  if (hayConexion) chEstado->notify();
}

void publicarConfiguracion(const char *texto) {
  if (chConfiguracion != nullptr) chConfiguracion->setValue(texto);
}

void avisarOrden(const char *orden) {
  if (chOrdenes == nullptr) return;
  chOrdenes->setValue(orden);
  if (hayConexion) chOrdenes->notify();
}

}  // namespace bluetooth

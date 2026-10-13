#include "dormir.h"

#include <Arduino.h>
#include <driver/gpio.h>
#include <esp_sleep.h>
#include <soc/soc_caps.h>

#if SOC_PM_SUPPORT_EXT1_WAKEUP
#include <driver/rtc_io.h>
#endif

// NOTA: comprobar con la placa real que despierta con el botón y que gasta poco.

void dormirHastaElBoton(uint8_t pinBoton) {
  gpio_num_t pin = static_cast<gpio_num_t>(pinBoton);

  // Esperar a que se suelte el botón para no despertar en seguida
  while (digitalRead(pinBoton) == LOW) delay(10);

#if SOC_PM_SUPPORT_EXT1_WAKEUP
  // ESP32-C6: el botón está en un pin de bajo consumo (LP GPIO 0 a 7)
  rtc_gpio_pullup_en(pin);
  rtc_gpio_pulldown_dis(pin);
  esp_sleep_enable_ext1_wakeup_io(1ULL << pinBoton, ESP_EXT1_WAKEUP_ANY_LOW);
#else
  // ESP32-C3 (XIAO): GPIO0 a GPIO5 pueden despertar a la placa
  gpio_pullup_en(pin);
  gpio_pulldown_dis(pin);
  gpio_hold_en(pin);
  gpio_deep_sleep_hold_en();
  esp_deep_sleep_enable_gpio_wakeup(1ULL << pinBoton, ESP_GPIO_WAKEUP_GPIO_LOW);
#endif

  Serial.println("Durmiendo. Presiona el boton para despertar.");
  Serial.flush();
  esp_deep_sleep_start();
}

bool despertoPorBoton() {
  esp_sleep_wakeup_cause_t causa = esp_sleep_get_wakeup_cause();
  return causa == ESP_SLEEP_WAKEUP_GPIO || causa == ESP_SLEEP_WAKEUP_EXT1;
}

void liberarBotonAlDespertar(uint8_t pinBoton) {
#if !SOC_PM_SUPPORT_EXT1_WAKEUP
  gpio_hold_dis(static_cast<gpio_num_t>(pinBoton));
  gpio_deep_sleep_hold_dis();
#else
  (void)pinBoton;
#endif
}

set(component_srcs "buzzer.c")

idf_component_register(SRCS "${component_srcs}"
    REQUIRES "driver" "esp_driver_ledc" "esp_driver_gpio"
    INCLUDE_DIRS "." "include")

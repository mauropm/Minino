idf_component_register(SRCS "ledc_controller.c"
    INCLUDE_DIRS "."
    REQUIRES driver esp_timer esp_driver_gpio esp_driver_ledc)

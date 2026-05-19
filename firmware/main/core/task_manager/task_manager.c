#include "task_manager.h"
#include "esp_log.h"
#include "string.h"
#include <inttypes.h>

static const char* TAG = "task_manager";

#define MAX_TASKS 50 // Máximo de tareas a trackear

// Array de tareas registradas
static task_info_t task_registry[MAX_TASKS];
static uint32_t task_count = 0;
static bool manager_initialized = false;

esp_err_t task_manager_init(void) {
#if !defined(CONFIG_TASK_MANAGER_DEBUG)
    esp_log_level_set(TAG, ESP_LOG_NONE);
#endif

    if (manager_initialized) {
        ESP_LOGW(TAG, "Task Manager ya inicializado");
        return ESP_OK;
    }

    // Limpiar registry
    memset(task_registry, 0, sizeof(task_registry));
    task_count = 0;

    ESP_LOGI(TAG, "Task Manager inicializado (capacidad: %d tareas)", MAX_TASKS);
    manager_initialized = true;
    return ESP_OK;
}

esp_err_t task_manager_register_task(const char* name, TaskHandle_t handle, uint32_t stack_size) {
    if (!manager_initialized) {
        ESP_LOGE(TAG, "Task Manager no inicializado");
        return ESP_FAIL;
    }

    if (task_count >= MAX_TASKS) {
        ESP_LOGE(TAG, "No hay espacio para más tareas (máx: %d)", MAX_TASKS);
        return ESP_FAIL;
    }

    task_registry[task_count].name = name;
    task_registry[task_count].handle = handle;
    task_registry[task_count].stack_size = stack_size;
    task_registry[task_count].is_running = true;
    task_count++;

    ESP_LOGI(TAG, "Tarea registrada: '%s'", name);
    return ESP_OK;
}

void task_manager_update_watermarks(void) {
    for (uint32_t i = 0; i < task_count; i++) {
        if (task_registry[i].is_running && task_registry[i].handle != NULL) {
            task_registry[i].stack_watermark = uxTaskGetStackHighWaterMark(task_registry[i].handle);
        }
    }
}

void task_manager_print_status(void) {
    task_manager_update_watermarks();

    ESP_LOGI(TAG, "=== Task Manager Status ===");
    ESP_LOGI(TAG, "Tareas registradas: %lu", (unsigned long)task_count);

    for (uint32_t i = 0; i < task_count; i++) {
        task_info_t* info = &task_registry[i];
        
        if (!info->is_running) continue;

        uint32_t used = info->stack_size - info->stack_watermark;
        float usage_percent = (info->stack_size > 0) ? 
            (float)used / info->stack_size * 100.0f : 0.0f;

        const char* status;
        if (info->stack_watermark < 128) {
            status = "DANGER";
        } else if (info->stack_watermark < 256) {
            status = "WARNING";
        } else {
            status = "OK";
        }

        ESP_LOGI(TAG, "[%2u] %-20s | %5" PRIu32 "/%5d bytes (%.1f%%) | %s", 
                (unsigned int)(i + 1),
                info->name, used, info->stack_size, usage_percent, status);
    }
}

bool task_manager_check_stack_overflow_risk(void) {
    task_manager_update_watermarks();

    for (uint32_t i = 0; i < task_count; i++) {
        if (task_registry[i].is_running) {
            if (task_registry[i].stack_watermark < 128) {
                ESP_LOGE(TAG, "Stack overflow risk: '%s' (solo %u bytes libres)",
                        task_registry[i].name,
                        (unsigned int)(task_registry[i].stack_watermark * sizeof(StackType_t)));
                return true;
            }
        }
    }

    return false;
}

esp_err_t task_manager_create(TaskFunction_t task_func, const char* name, task_stack_size_t stack_size, void* params, task_priority_t priority, TaskHandle_t* handle) {
    if (!manager_initialized) {
        ESP_LOGE(TAG, "Task Manager no inicializado");
        return ESP_FAIL;
    }

    if (task_count >= MAX_TASKS) {
        ESP_LOGE(TAG, "No hay espacio para más tareas (máx: %d)", MAX_TASKS);
        return ESP_FAIL;
    }

    // Create the task
    TaskHandle_t task_handle;
    BaseType_t result = xTaskCreate(task_func, name, stack_size, params, priority, &task_handle);
    
    if (result != pdPASS) {
        ESP_LOGE(TAG, "Failed to create task: %s", name);
        return ESP_FAIL;
    }

    // Register the task
    task_registry[task_count].name = name;
    task_registry[task_count].handle = task_handle;
    task_registry[task_count].stack_size = stack_size;
    task_registry[task_count].is_running = true;
    task_registry[task_count].stack_watermark = stack_size;
    task_count++;

    if (handle != NULL) {
        *handle = task_handle;
    }

    ESP_LOGI(TAG, "Task created: '%s' (stack: %d, priority: %d)", name, stack_size, priority);
    return ESP_OK;
}

esp_err_t task_manager_delete(TaskHandle_t handle) {
    if (handle == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    // Find and remove from registry
    for (uint32_t i = 0; i < task_count; i++) {
        if (task_registry[i].handle == handle) {
            task_registry[i].is_running = false;
            task_registry[i].handle = NULL;
            vTaskDelete(handle);
            ESP_LOGI(TAG, "Task deleted: '%s'", task_registry[i].name);
            return ESP_OK;
        }
    }

    // If not found in registry, just delete it
    vTaskDelete(handle);
    return ESP_OK;
}

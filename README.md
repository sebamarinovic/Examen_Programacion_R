# 📊 Dashboard de Análisis Térmico EP-110

## 🔍 Descripción

Esta aplicación **Shiny** permite monitorear y analizar el desempeño térmico de los equipos **EP-110** en plantas GCP-2 y GCP-4, utilizando un modelo predictivo **XGBoost** para estimar el comportamiento de la temperatura de salida de agua (**Temperatura**) en función de factores operacionales clave.

El dashboard es interactivo y entrega visualizaciones, métricas y recomendaciones operacionales en base al análisis de eficiencia térmica.

---

## ⚙️ Estructura de la App

- **Inputs del usuario:**
  - Selección de **rango de fechas**
  - Selección de **planta**

- **Outputs principales:**
  - 🔍 **Equipos críticos** por desempeño térmico (Δ Agua)
  - 🛠️ **Ciclos de mantenimiento** detectados en el periodo
  - 🤖 **Modelo predictivo XGBoost**
    - Entrenado en tiempo real
    - Evaluación con RMSE y R²
    - Comparación de valores reales vs predichos
  - 📈 **Visualizaciones**
    - Serie temporal de Δ Agua
    - Boxplot por equipo
    - Correlaciones térmicas

---

## 🧠 Modelo Predictivo

Se entrena un modelo de regresión con `xgboost` para predecir la variable:

- **Temperatura (salida de agua)**

Usando como predictores:

- `Delta.Agua`
- `Temp.Entrada.Agua.Torre`
- `TempGas` (temperatura de gases de combustión)
- `Grupo_Tren_Equipo` (factor operacional)

**Métricas de evaluación (en conjunto de prueba):**

- `RMSE`: Error cuadrático medio
- `R²`: Capacidad explicativa del modelo

---

## 📁 Archivos necesarios

- `data.csv` → Datos de operación por equipo 
- `temp_gcp_data.csv` → Temperatura de gases 
- `app.R` o script dividido en `ui.R` y `server.R`

---

## 🚀 Cómo ejecutar

```r
# Instalar dependencias si no las tienes
install.packages(c("shiny", "tidyverse", "lubridate", "DT", "plotly", "glue", "xgboost", "caret", "earth"))

# Ejecutar app
shiny::runApp(https://sebamarinovic.shinyapps.io/Examen/)
```

##💡 Interpretación operativa
- Los valores de Δ Agua menores a 4 °C indican eficiencia térmica baja ❄️
- El modelo permite detectar patrones no lineales y anticipar pérdida de rendimiento
- Equipos con alta frecuencia bajo el umbral crítico deben ser priorizados para mantención preventiva

✍️ Autoría
Desarrollado por Sebastian Marinovic Leiva

📦 Basado en R + Shiny + ML con xgboost
📅 Fecha: Junio 2025

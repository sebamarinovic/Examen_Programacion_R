# 📊 Dashboard de Análisis Térmico EP-110

## 🔍 Descripción

Este dashboard interactivo desarrollado en R + Shiny permite el análisis operacional y predictivo del sistema de enfriamiento EP-110 en plantas GCP-2 y GCP-4.
El objetivo es apoyar la toma de decisiones mediante la visualización de métricas térmicas clave y modelos de machine learning interpretables.

---

## 🧪 Funcionalidades Principales
### 🔍 Exploración de Datos Operacionales:
  - Δ Agua por equipo y fecha
  - Temperatura de entrada y simulada de gases (TempGas) 
  - Intervenciones de mantenimiento (modo resumen y gráfico)

### 📈 Modelado Predictivo:
  - Entrenamiento de modelo XGBoost
  - Predicción de Δ Agua en función de variables operacionales
  - Evaluación del modelo con RMSE y R²

### 🧠 Interpretabilidad:
  - Gráfico PDP (Partial Dependence Plot) de TempGas
  - Cálculo de pendiente estimada para interpretar influencia de TempGas sobre Δ Agua

### 🧾 Resumen Ejecutivo:
- Última lectura de TempGas
- Equipo más crítico según % bajo 4 °C
- Diagnóstico de mantenimiento
- Indicadores de desempeño del modelo

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
https://sebamarinovic.shinyapps.io/Examen/
```

## 💡 Interpretación operativa
- Los valores de Δ Agua menores a 4 °C indican eficiencia térmica baja.
- El modelo permite detectar patrones no lineales y anticipar pérdida de rendimiento.
- Equipos con alta frecuencia bajo el umbral crítico deben ser priorizados para mantención preventiva.

✍️ Autoría
Desarrollado por Sebastian Marinovic Leiva.

📦 Basado en R + Shiny + ML con xgboost
📅 Fecha: Junio 2025

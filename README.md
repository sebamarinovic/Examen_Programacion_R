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

### 📊 Capturas de ejemplo
![image](https://github.com/user-attachments/assets/1136b320-e871-431a-a4b5-147d277ce123)

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
https://sebamarinovic.shinyapps.io/Examen_R/
```

## 💡 Interpretación operativa
- Los valores de Δ Agua menores a 4 °C indican eficiencia térmica baja.
- El modelo permite detectar patrones no lineales y anticipar pérdida de rendimiento.
- Equipos con alta frecuencia bajo el umbral crítico deben ser priorizados para mantención preventiva.

# 📘 Modelamiento Térmico Operacional — Informe RMarkdown

Este documento contiene el desarrollo analítico del comportamiento térmico en las plantas industriales **GCP-2** y **GCP-4**, usando herramientas estadísticas y de machine learning para entender y predecir  como afecta el rendimiento de los enfriadores, en relación con variables críticas del sistema de enfriamiento tal como la temperatura de gases de salida. 

---

## 📌 Objetivo del Informe

- Analizar la relación entre **Δ Agua** y la **temperatura de gases de salida**.
- Evaluar el aporte de variables operativas como:
  - `Temp.Entrada.Agua.Torre`
  - `Grupo_Tren_Equipo` (línea A/B, planta GCP-2/4)
  - `TempGas` promedio diario
- Comparar el rendimiento de distintos modelos de regresión aplicados al problema.

---

## 🧪 Modelos Comparados

Se construyen y validan los siguientes modelos predictivos para estimar `Temperatura`:

| Modelo             | Variables Consideradas                                         | Notas |
|--------------------|---------------------------------------------------------------|-------|
| Lineal Simple      | Solo `Delta.Agua`                                             | Referencial |
| Lineal Múltiple    | `Delta.Agua`, `Temp.Entrada.Agua.Torre`, `TempGas`, `Grupo_Tren_Equipo` | Base extendida |
| Polinomial         | Término cuadrático en `Delta.Agua` + variables múltiples      | Modela no linealidad parcial |
| GAM                | Ajuste suave sobre `Delta.Agua`                               | Flexible y explicativo |
| MARS               | Modelos aditivos multivariados con particiones                | Interpretable y no lineal |
| XGBoost            | Árboles de decisión optimizados                               | 🏆 Mejor desempeño |

---

## 📊 Resultados Comparativos

| Modelo          | RMSE    | R² (%)  |
|-----------------|---------|---------|
| Lineal Simple   | 4.38    | 2.2     |
| Lineal Múltiple | 1.88    | 82.1    |
| Polinomial      | 1.84    | 82.7    |
| GAM             | 1.85    | 82.6    |
| MARS            | 1.85    | 82.5    |
| **XGBoost**     | **1.13**| **93.5**|

🔴 *XGBoost* es el modelo con **mayor precisión predictiva**, logrando un ajuste sobresaliente con R² ≈ 93.5%.
![image](https://github.com/user-attachments/assets/e1f5bba4-5d1f-4f8f-b0b6-bb263164c993)
---

## 📊 Resultados del Análisis PDP

Se utilizó la librería `pdp` para analizar el efecto marginal de `TempGas` sobre `Δ Agua` usando el modelo entrenado `XGBoost`.

🔺 **Pendiente PDP (TempGas → Δ Agua):**  
> Por cada incremento de **1 °C en TempGas**, se estima una **disminución de `X` °C en Δ Agua**.  
> Este valor fue estimado mediante ajuste lineal al gráfico de dependencia parcial.

✏️ Este resultado entrega una **interpretación cuantitativa** crucial para comprender cómo afecta el sobrecalentamiento del sistema de gases a la eficiencia térmica del sistema de enfriamiento.

![image](https://github.com/user-attachments/assets/64613117-13d2-4994-ba96-cfef7278d259)

---

## 🖥️ Aplicación Shiny

El proyecto cuenta con una app `Shiny` para diagnóstico operativo que incluye:

- Identificación de **equipos críticos**.
- Visualización de **ciclos de mantenimiento**.
- Series de tiempo y boxplots de Δ Agua.
- Análisis automatizado con XGBoost.

---

## 📦 Requisitos

```r
install.packages(c("tidyverse", "xgboost", "caret", "earth", "mgcv", "lubridate", "patchwork"))
```

## ✍️ Autor
**Sebastian Marinovic Leiva** 

📦 Basado en R + Shiny + ML con xgboost
📄 RMarkdown: modelamiento.Rmd
🧠 Proyecto: Análisis de Eficiencia Térmica EP-110
📅 Fecha: Julio 2025

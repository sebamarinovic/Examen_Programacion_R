# 📊 Dashboard de Análisis Térmico EP-110


## 🎬 Video Explicativo del Proyecto
Para complementar la entrega, se incluye un video donde se explica en detalle el desarrollo del proyecto, la función analisis_ep110, el modelado con XGBoost y el funcionamiento de la aplicación Shiny.

###🎥 Ver video explicativo:
🔗 https://drive.google.com/file/d/1_CxHEm_cfOvw92n2mzeJveQxckkL0qm5/view?usp=sharing


## 🔍 Descripción

Este proyecto busca analizar el comportamiento térmico del sistema de enfriamiento **EP-110** en las plantas industriales **GCP-2** y **GCP-4**, mediante una aplicación `Shiny` en R. Se combina exploración de datos, visualización interactiva y modelado predictivo con técnicas de machine learning para asistir la toma de decisiones operativas y de mantenimiento.

---

## 🧪 Funcionalidades Principales
### 📉 Exploración de datos
- Series de tiempo y boxplots de Δ Agua por equipo.
- Estadísticas de ciclos de mantenimiento.
- Evolución de TempGas por planta.

### ⚙️ Modelamiento predictivo
- Entrenamiento con XGBoost (`xgboost`, `caret`).
- Predicción de Δ Agua en función de `Temp Entrada Agua Torre`, `TempGas` y clasificación `Grupo_Tren_Equipo`.
- Métricas de evaluación: RMSE y R².

### 🔬 Interpretabilidad
- Gráfico PDP (`pdp`) de `TempGas → Δ Agua`.
- Cálculo de pendiente estimada para interpretación operativa.

### 🧾 Diagnóstico Ejecutivo Automático
- Última lectura de `TempGas`.
- Equipo más crítico por % registros con Δ Agua < 4 °C.
- Estado de mantenciones.
- Desempeño del modelo predictivo.
- 
### 📊 Capturas de ejemplo
![image](https://github.com/user-attachments/assets/1136b320-e871-431a-a4b5-147d277ce123)

---

## 📁 Archivos necesarios

| Archivo                     | Descripción                                         |
|-----------------------------|-----------------------------------------------------|
| `app.R`                    | App principal en R + Shiny                          |
| `Modelamiento.Rmd`         | Informe analítico en RMarkdown                     |
| `data.csv`                 | Dataset principal con registros de operación        |
| `temp_gcp_data.csv`        | Datos complementarios de temperatura de gases       |
| `Examen R Data Science_final.pdf` | Instrucciones y rúbrica del examen         |

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

# 📘 Modelamiento Térmico Operacional

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

![image](https://github.com/user-attachments/assets/dedb3d0d-5cde-4aed-b71e-86f2c2ae32a2)

---

## 📊 Resultados del Análisis PDP

Se utilizó la librería `pdp` para analizar el efecto marginal de `TempGas` sobre `Δ Agua` usando el modelo entrenado `XGBoost`.

🔺 **Pendiente PDP (TempGas → Δ Agua):**  
> Por cada incremento de **1 °C en TempGas**, se estima una **disminución de `X` °C en Δ Agua**.  
> Este valor fue estimado mediante ajuste lineal al gráfico de dependencia parcial.

✏️ Este resultado entrega una **interpretación cuantitativa** crucial para comprender cómo afecta el sobrecalentamiento del sistema de gases a la eficiencia térmica del sistema de enfriamiento.

![image](https://github.com/user-attachments/assets/28777f04-2c24-4aef-9c07-f379a623de95)


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

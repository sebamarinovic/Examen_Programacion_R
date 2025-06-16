# 📘 Modelamiento del Desempeño Térmico en Torres de Enfriamiento

## 📌 Descripción General

Este proyecto desarrolla un modelo de **regresión lineal múltiple** para analizar el comportamiento térmico de los **enfriadores EP-110** en sistemas industriales. El objetivo es predecir el valor de `Δ Agua` (diferencia de temperatura entre entrada y salida del agua de torre) en función de variables operativas, con el fin de:

- Priorizar mantenimientos preventivos.
- Identificar equipos con bajo desempeño.
- Integrar el análisis a sistemas de monitoreo y toma de decisiones.

---

## 🔍 Objetivos del Análisis

- Modelar la variable dependiente `Δ Agua` usando variables predictoras como:
  - Temperatura de entrada del agua torre (`Temp Entrada Agua Torre`)
  - Estado del equipo (`Estado`)
  - Tipo de equipo (`Equipo`)
- Validar los supuestos clásicos de regresión:
  - Normalidad de residuos
  - Homocedasticidad
  - Linealidad
  - Identificación de puntos influyentes (Distancia de Cook)
- Analizar el impacto de cada predictor en la eficiencia térmica
- Proveer soporte cuantitativo para decisiones de mantenimiento industrial

---

## 🛠 Variables Clave

| Variable                     | Tipo     | Descripción                                              |
|-----------------------------|----------|----------------------------------------------------------|
| `Δ Agua`                    | Numérica | Temperatura salida - entrada del agua (°C)              |
| `Temp Entrada Agua Torre`   | Numérica | Temperatura de entrada del agua a la torre (°C)         |
| `Estado`                    | Factor   | Estado operativo del equipo (`En Servicio`, `Mantención`)|
| `Equipo`                    | Factor   | Identificador del enfriador EP-110 A-F                  |

---

## 📈 Resultados del Modelo

- **Significancia estadística** en los coeficientes de:
  - Estado del equipo: `Mantención` reduce significativamente el ΔT
  - Varios equipos con menor eficiencia promedio (especialmente A, C, E)
- **Bondad de ajuste**:  
  - R² Ajustado ≈ 50.7%  
  - Error estándar residual ≈ 1.20°C

---

## 📊 Validaciones Visuales

Gráficos incluidos para validar el modelo:

- 📉 Residuos vs Valores Ajustados: evaluación de homocedasticidad
- 📐 QQ Plot: validación de normalidad en residuos
- 🧠 Distancia de Cook vs Leverage: identificación de outliers influyentes

---

## 💡 Interpretación Operacional

- Equipos con `Δ Agua < 4°C` en más del 20% de los registros son considerados **críticos** y priorizables para mantenimiento.
- El modelo permite explicar cómo afectan las variables operativas a la eficiencia térmica.
- Integrado con dashboards (ver `app.R`), se convierte en herramienta de monitoreo continuo.

---

## 📂 Archivos Relevantes
- data.csv # Datos operativos EP-110
- temp_gcp_data.csv # Temperaturas de gases
- analisis_ep110.R # Función modular para análisis
- app.R # App Shiny interactiva
- README.md # Este documento

---

## 🚀 Aplicación Interactiva

Se implementa una app con **Shiny** que permite:

- Filtrar por fechas y plantas
- Visualizar equipos críticos, mantenimientos y correlaciones térmicas
- Explorar el modelo de regresión y sus validaciones gráficas
- Tomar decisiones basadas en datos operativos actualizados

**URL de la app (si publicada en shinyapps.io)**:  
📎 ` https://sebamarinovic.shinyapps.io/Examen/`

---

## 🧪 Requisitos

```r
install.packages(c("shiny", "tidyverse", "lubridate", "plotly", "DT", "broom"))
```

## 👨‍🔧 Autor
Sebastián Marinovic
Magíster en Ciencia de Datos — Universidad de las Américas, 2025

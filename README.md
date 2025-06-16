# 1. Modelamiento Estadístico – Análisis de Δ Agua
Este proyecto tiene como objetivo modelar y analizar el comportamiento térmico de los enfriadores EP-110 en función de variables operativas, para contribuir a la toma de decisiones de mantenimiento en entornos industriales.

## Análisis realizado
- Modelo de regresión lineal múltiple para predecir Δ Agua
  - Variables independientes: Temperatura Entrada Agua, Estado, Equipo
  - Se evaluaron supuestos de linealidad, normalidad, homocedasticidad e influencia (Cook's distance)
- Visualizaciones de diagnóstico
  - Residuos vs Ajustados
  - QQ Plot de residuos
  - Distancia de Cook vs Leverage
- Correlación térmica
  - Relación entre temperatura de gases y Δ Agua
- Identificación de equipos críticos
  - Con base en porcentaje de registros bajo 4°C y Δ Agua promedio
- Análisis de ciclos de mantenimiento
  - Fechas de intervención y equipos afectados

## Archivos clave
- data.csv: Datos operacionales de los enfriadores
- temp_gcp_data.csv: Temperatura de gases (diaria)
- analisis_ep110.R: Función modular que ejecuta todo el análisis
- Modelamiento_Final.pdf: Informe técnico generado a partir del análisis
- app.R: App Shiny interactiva para monitoreo

# 2. Aplicación Web Interactiva con Shiny – Dashboard EP-110
La aplicación web (app.R) permite visualizar y analizar dinámicamente el rendimiento térmico de los enfriadores EP-110.

## Funcionalidades principales
- Filtro por rango de fechas y planta (GCP-2, GCP-4, etc.)
- Visualización de:
  - Equipos críticos
  - Ciclos de mantenimiento
  - Correlación entre temperatura de gases y Δ Agua
  - Modelo de regresión y sus validaciones
  - Visualizaciones de Δ Agua en tiempo y distribución

## Estructura esperada del proyecto
📂 /ep110_dashboard/
├── app.R
├── analisis_ep110.R
├── data.csv
├── temp_gcp_data.csv
├── Modelamiento_Final.pdf
└── README.md

## Publicación online
Esta app ha sido publicada en shinyapps.io y está accesible en:
https://<usuario>.shinyapps.io/<nombre_app>


👨‍🔬 Requisitos
R >= 4.2.0

Paquetes necesarios:

r
Copiar
Editar
install.packages(c(
  "shiny", "tidyverse", "lubridate", "plotly",
  "DT", "broom", "rsconnect"
))
✏️ Uso
r
Copiar
Editar
# Para ejecutar localmente
shiny::runApp("app.R")
r
Copiar
Editar
# Para desplegar en shinyapps.io
rsconnect::setAccountInfo(name=..., token=..., secret=...)
rsconnect::deployApp(appDir = ".", appName = "dashboard_ep110")
✍️ Autor
Sebastián Marinovic

Proyecto académico – Magíster Data Science – 2025

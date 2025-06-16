# ==== LIBRERÍAS ====
library(shiny)
library(tidyverse)
library(lubridate)
library(DT)
library(plotly)
library(glue)
library(earth)
library(rsconnect)

# ==== FUNCIÓN PRINCIPAL ====
analisis_ep110 <- function(ep_data, gcp_data = NULL, fecha_inicio = NULL, fecha_fin = NULL) {
  if (!"FechaHora" %in% names(ep_data)) {
    ep_data <- ep_data %>% mutate(FechaHora = ymd_hms(paste(Fecha, Hora)))
  }
  
  ep_data <- ep_data %>%
    mutate(Fecha = as.Date(FechaHora)) %>%
    filter(Fecha >= as.Date(fecha_inicio),
           Fecha <= as.Date(fecha_fin),
           !is.na(`Delta Agua`)) %>%
    mutate(Estado = as.factor(Estado), Equipo = as.factor(Equipo))
  
  resumen_equipo <- ep_data %>%
    group_by(Equipo) %>%
    summarise(
      promedio_dt = mean(`Delta Agua`, na.rm = TRUE),
      pct_bajo = mean(`Delta Agua` < 4, na.rm = TRUE) * 100,
      .groups = "drop"
    )
  
  equipos_criticos <- resumen_equipo %>%
    arrange(desc(pct_bajo), promedio_dt) %>%
    slice_head(n = 1)
  
  ciclos_mantenimiento <- ep_data %>%
    filter(Estado == "Mantención") %>%
    group_by(Planta, Fecha = as.Date(FechaHora)) %>%
    summarise(
      equipos_intervenidos = n_distinct(Equipo),
      nombres_equipos = paste(unique(Equipo), collapse = ", "),
      .groups = "drop"
    )
  
  g_mant <- ggplot(ciclos_mantenimiento, aes(x = Fecha, y = equipos_intervenidos, text = nombres_equipos)) +
    geom_col(fill = "#4682B4") +
    labs(title = "Intervenciones de Mantenimiento por Fecha", x = "Fecha", y = "N° Equipos") +
    theme_minimal()
  
  # === Modelo MARS ===
  modelo_mars <- earth(`Delta Agua` ~ `Temp Entrada Agua Torre` + Estado + Equipo, data = ep_data)
  pred_mars <- predict(modelo_mars)
  rmse_mars <- sqrt(mean((ep_data$`Delta Agua` - pred_mars)^2))
  r2_mars <- 1 - sum((ep_data$`Delta Agua` - pred_mars)^2) / sum((ep_data$`Delta Agua` - mean(ep_data$`Delta Agua`))^2)
  
  g_mars <- ggplot(ep_data, aes(x = `Delta Agua`, y = pred_mars)) +
    geom_point(alpha = 0.5, color = "#E69F00") +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
    labs(title = "MARS: Valores Reales vs Predichos",
         x = "Δ Agua Observada", y = "Δ Agua Predicha") +
    theme_minimal()
  
  modelo_mars_resultado <- list(
    modelo = modelo_mars,
    rmse = rmse_mars,
    r2 = r2_mars,
    pred = pred_mars,
    grafico = g_mars
  )
  
  g1 <- ggplot(ep_data, aes(x = FechaHora, y = `Delta Agua`, color = Equipo)) +
    geom_line() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Serie Temporal de Δ Agua", y = "Δ Agua (°C)", x = "FechaHora")
  
  g2 <- ggplot(ep_data, aes(x = Equipo, y = `Delta Agua`, fill = Estado)) +
    geom_boxplot() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Distribución de Δ Agua por Equipo", y = "Δ Agua", x = "Equipo")
  
  return(list(
    equipos_criticos = equipos_criticos,
    ciclos_mantenimiento = ciclos_mantenimiento,
    modelo_mars = modelo_mars_resultado,
    graficos = list(
      serie = g1,
      boxplot = g2,
      mant = g_mant
    ),
    data = ep_data
  ))
}

# ==== DATOS ====
ep_data <- read_csv("data.csv")
if (!"FechaHora" %in% names(ep_data)) {
  ep_data <- ep_data %>% mutate(FechaHora = ymd_hms(paste(Fecha, Hora)))
}

# ==== UI ====
ui <- fluidPage(
  titlePanel("Dashboard de Análisis Térmico EP-110"),
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("fechas", "Seleccionar rango de fechas:",
                     start = min(ep_data$FechaHora),
                     end = max(ep_data$FechaHora)),
      selectInput("planta", "Seleccionar planta:", choices = unique(ep_data$Planta)),
      actionButton("analizar", "Ejecutar análisis")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Equipos Críticos", 
                 DTOutput("tabla_criticos"), 
                 uiOutput("texto_criticos")),
        
        tabPanel("Ciclos de Mantenimiento", 
                 DTOutput("tabla_mant"), 
                 uiOutput("texto_mant"), 
                 plotlyOutput("graf_mant")),
        
        tabPanel("Modelo MARS",
                 checkboxInput("show_model", "✅ Modelo MARS (earth)", value = TRUE),
                 verbatimTextOutput("mars_summary"),
                 plotlyOutput("mars_plot"),
                 uiOutput("texto_operacional")),
        
        tabPanel("Visualizaciones",
                 plotlyOutput("graf1"),
                 plotlyOutput("graf2"),
                 uiOutput("texto_graficos"))
      )
    )
  )
)

# ==== SERVER ====
server <- function(input, output, session) {
  resultados <- reactiveValues()
  
  observeEvent(input$analizar, {
    data_filtrada <- ep_data %>%
      filter(Planta == input$planta,
             FechaHora >= input$fechas[1],
             FechaHora <= input$fechas[2])
    
    r <- analisis_ep110(ep_data = data_filtrada,
                        fecha_inicio = input$fechas[1],
                        fecha_fin = input$fechas[2])
    
    resultados$criticos <- r$equipos_criticos
    resultados$mant <- r$ciclos_mantenimiento
    resultados$modelo_mars <- r$modelo_mars
    resultados$graficos <- r$graficos
    resultados$data <- r$data
  })
  
  # === TABLAS ===
  output$tabla_criticos <- renderDT({ req(resultados$criticos); datatable(resultados$criticos) })
  output$tabla_mant <- renderDT({ req(resultados$mant); datatable(resultados$mant) })
  
  # === GRÁFICOS ===
  output$graf1 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$serie) })
  output$graf2 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$boxplot) })
  output$graf_mant <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$mant, tooltip = "text") })
  output$mars_plot <- renderPlotly({ req(resultados$modelo_mars); ggplotly(resultados$modelo_mars$grafico) })
  
  # === TEXTO MARS ===
  output$mars_summary <- renderPrint({
    req(resultados$modelo_mars)
    glue("✅ Modelo MARS (earth)\n\nRMSE: {round(resultados$modelo_mars$rmse, 3)}\nR²: {round(resultados$modelo_mars$r2, 3)}")
  })
  
  # === INTERPRETACIONES ===
  output$texto_criticos <- renderUI({
    req(resultados$criticos)
    eq <- resultados$criticos
    HTML(glue("<p>🔍 <strong>Equipo más crítico:</strong> {eq$Equipo} <br>
               🌡️ <strong>ΔT Promedio:</strong> {round(eq$promedio_dt, 2)} °C <br>
               ⚠️ <strong>% bajo 4°C:</strong> {round(eq$pct_bajo, 1)}%</p>"))
  })
  
  output$texto_mant <- renderUI({
    req(resultados$mant)
    fechas <- resultados$mant$Fecha
    ultima <- max(fechas)
    dias_prom <- round(mean(diff(sort(fechas))))
    equipos <- unique(unlist(strsplit(resultados$mant$nombres_equipos, ", ")))
    total <- 6
    intervenidos <- length(unique(equipos))
    HTML(glue("
      <p><strong>🛠️ Estadísticas de Mantención:</strong></p>
      <ul>
        <li>📅 Última mantención: {format(ultima, '%d/%m/%Y')}</li>
        <li>⏳ Promedio entre mantenimientos: {dias_prom} días</li>
        <li>🔧 Equipos intervenidos: {intervenidos}/{total}</li>
        <li>🚨 <strong>Recomendación:</strong> Revisar equipos no intervenidos</li>
      </ul>
    "))
  })
  
  output$texto_operacional <- renderUI({
    req(resultados$modelo_mars)
    r2 <- round(resultados$modelo_mars$r2 * 100, 1)
    HTML(glue("
      <p><strong>📊 Interpretación Operacional:</strong></p>
      <p>🔎 El modelo MARS permite identificar patrones no lineales entre la eficiencia térmica (Δ Agua) y variables como la temperatura de entrada o el estado del equipo.</p>
      <p>📈 Con un R² de aproximadamente <strong>{r2}%</strong>, el modelo tiene una capacidad explicativa moderada 💡, útil para orientar decisiones de mantenimiento preventivo y operativo.</p>
      <p>✅ Esto permite priorizar equipos con menor rendimiento térmico 🧊 y facilitar la planificación de intervenciones según condiciones reales de operación.</p>
    "))
  })
  
  output$texto_graficos <- renderUI({
    req(resultados$data)
    data <- resultados$data
    total <- nrow(data)
    bajo_4 <- sum(data$`Delta Agua` < 4, na.rm = TRUE)
    pct_bajo <- round(100 * bajo_4 / total, 1)
    
    equipos_bajo <- data %>%
      group_by(Equipo) %>%
      summarise(pct = mean(`Delta Agua` < 4, na.rm = TRUE) * 100) %>%
      filter(pct > 0) %>%
      arrange(desc(pct))
    
    HTML(glue("
      <h4>🔎 Interpretación Operacional de Visualizaciones</h4>
      <p>📉 En el gráfico temporal se observa la evolución de la eficiencia térmica (Δ Agua) para cada equipo en el tiempo. Las líneas por debajo del umbral de 4 °C (línea roja punteada) indican desempeño deficiente o riesgo operacional.</p>

      <p>📦 En el boxplot, se visualiza la dispersión del rendimiento térmico por equipo. Equipos con mediana por debajo de 4 °C requieren atención especial ⚠️.</p>

      <p>📊 De un total de <b>{total}</b> registros, <b>{bajo_4}</b> (es decir, <b>{pct_bajo}%</b>) se encuentran por debajo del umbral crítico de Δ Agua.</p>

      <p>🔧 <strong>Equipos con mayor proporción de bajo rendimiento:</strong></p>
      <ul>
        {paste0('<li>🔻 ', equipos_bajo$Equipo, ': ', round(equipos_bajo$pct, 1), '% bajo 4 °C</li>', collapse = '')}
      </ul>

      <p>🧩 Esta información ayuda a <b>focalizar mantenimientos</b> y ajustar condiciones operativas para mejorar la eficiencia térmica del sistema. Se recomienda monitorear en tiempo real estos indicadores para evitar deterioros progresivos. 💡</p>
    "))
  })
}

# ==== RUN ====
shinyApp(ui, server)



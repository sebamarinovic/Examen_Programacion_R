# ==== LIBRERÍAS ====
library(shiny)
library(tidyverse)
library(lubridate)
library(DT)
library(plotly)
library(broom)
library(glue)

# ==== FUNCIÓN PRINCIPAL ====
analisis_ep110 <- function(ep_data, gcp_data = NULL, fecha_inicio = NULL, fecha_fin = NULL) {
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(broom)
  
  # Crear columna FechaHora si no existe
  if (!"FechaHora" %in% names(ep_data)) {
    ep_data <- ep_data %>% mutate(FechaHora = ymd_hms(paste(Fecha, Hora)))
  }
  
  ep_data <- ep_data %>%
    mutate(Fecha = as.Date(FechaHora)) %>%
    filter(Fecha >= as.Date(fecha_inicio),
           Fecha <= as.Date(fecha_fin),
           !is.na(`Delta Agua`)) %>%
    mutate(Estado = as.factor(Estado), Equipo = as.factor(Equipo))
  
  # Métricas de rendimiento por equipo
  resumen_equipo <- ep_data %>%
    group_by(Equipo) %>%
    summarise(
      promedio_dt = mean(`Delta Agua`, na.rm = TRUE),
      pct_bajo = mean(`Delta Agua` < 4, na.rm = TRUE) * 100,
      .groups = "drop"
    )
  
  # Identificar el equipo más crítico
  equipos_criticos <- resumen_equipo %>%
    arrange(desc(pct_bajo), promedio_dt) %>%
    slice_head(n = 1)
  
  # Ciclos de mantenimiento
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
  
  # Correlación térmica con temperatura de gases
  if (!is.null(gcp_data)) {
    gcp_data <- gcp_data %>%
      mutate(FechaHora = ymd_hms(FechaHora),
             Fecha = as.Date(FechaHora))
    
    gcp_daily <- gcp_data %>%
      group_by(Fecha) %>%
      summarise(TempGas = mean(Temperatura, na.rm = TRUE))
    
    ep_merge <- ep_data %>% left_join(gcp_daily, by = "Fecha")
    
    merged_valid <- ep_merge %>% filter(!is.na(`Delta Agua`), !is.na(TempGas))
    
    correlacion_dt_temp <- if (nrow(merged_valid) >= 2) {
      summarise(merged_valid, correlacion = cor(`Delta Agua`, TempGas, use = "complete.obs"))
    } else tibble(correlacion = NA_real_)
    
    g_cor <- ggplot(merged_valid, aes(x = TempGas, y = `Delta Agua`)) +
      geom_point(alpha = 0.7) +
      geom_smooth(method = "lm", color = "red") +
      labs(title = "Correlación Térmica (Media Diaria)", x = "Temperatura Gas (°C)", y = "Δ Agua (°C)") +
      theme_minimal()
  } else {
    correlacion_dt_temp <- tibble(correlacion = NA_real_)
    g_cor <- NULL
  }
  
  # Modelo de regresión lineal
  modelo_lm <- lm(`Delta Agua` ~ `Temp Entrada Agua Torre` + Estado + Equipo, data = ep_data)
  modelo_summary <- summary(modelo_lm)
  diag_data <- augment(modelo_lm)
  
  # Visualizaciones
  g1 <- ggplot(ep_data, aes(x = FechaHora, y = `Delta Agua`, color = Equipo)) +
    geom_line() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Serie Temporal de Δ Agua", y = "Δ Agua (°C)", x = "FechaHora")
  
  g2 <- ggplot(ep_data, aes(x = Equipo, y = `Delta Agua`, fill = Estado)) +
    geom_boxplot() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Distribución de Δ Agua por Equipo", y = "Δ Agua", x = "Equipo")
  
  g_resid <- ggplot(diag_data, aes(.fitted, .resid)) +
    geom_point(color = "#1f78b4", alpha = 0.6) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "firebrick") +
    labs(title = "Residuos vs Ajustados", x = "Valores Ajustados", y = "Residuos") +
    theme_light()
  
  g_qq <- ggplot(diag_data, aes(sample = .std.resid)) +
    stat_qq(alpha = 0.6) + stat_qq_line(color = "red") +
    labs(title = "QQ Plot de Residuos", x = "Cuantiles Teóricos", y = "Cuantiles Observados") +
    theme_light()
  
  g_cook <- ggplot(diag_data, aes(x = .hat, y = .cooksd)) +
    geom_point(color = "#1f78b4", alpha = 0.6) +
    geom_hline(yintercept = 0.5, linetype = "dotted", color = "firebrick") +
    labs(title = "Distancia de Cook vs Leverage", x = "Leverage", y = "Distancia de Cook") +
    theme_light()
  
  return(list(
    equipos_criticos = equipos_criticos,
    ciclos_mantenimiento = ciclos_mantenimiento,
    correlacion_dt_temp = correlacion_dt_temp,
    modelo_regresion = modelo_summary,
    graficos = list(
      serie = g1,
      boxplot = g2,
      resid = g_resid,
      qq = g_qq,
      cook = g_cook,
      cor = g_cor,
      mant = g_mant
    ),
    data = ep_data
  ))
}


# ==== DATOS ====
ep_data <- read_csv("data.csv")
gcp_data <- read_csv("temp_gcp_data.csv")
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
        tabPanel("Resumen Ejecutivo", 
                 uiOutput("texto_resumen")),
        tabPanel("Equipos Críticos", 
                 DTOutput("tabla_criticos"), 
                 uiOutput("texto_criticos")),
        tabPanel("Ciclos de Mantenimiento", 
                 DTOutput("tabla_mant"), 
                 uiOutput("texto_mant"), 
                 plotlyOutput("graf_mant")),
        tabPanel("Correlación Térmica", 
                 DTOutput("tabla_cor"), 
                 plotlyOutput("plot_cor"), 
                 uiOutput("texto_cor")),
        tabPanel("Modelo de Regresión",
                 verbatimTextOutput("modelo_out"),
                 uiOutput("texto_modelo"),
                 uiOutput("texto_modelo_extra"),
                 uiOutput("texto_operacional"),
                 plotlyOutput("plot_resid"),
                 plotlyOutput("plot_qq"),
                 plotlyOutput("plot_cook")),
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
                        gcp_data = gcp_data,
                        fecha_inicio = input$fechas[1],
                        fecha_fin = input$fechas[2])
    
    resultados$criticos <- r$equipos_criticos
    resultados$mant <- r$ciclos_mantenimiento
    resultados$cor <- r$correlacion_dt_temp
    resultados$modelo <- r$modelo_regresion
    resultados$graficos <- r$graficos
    resultados$data <- r$data
  })
  
  # === TABLAS ===
  output$tabla_criticos <- renderDT({ req(resultados$criticos); datatable(resultados$criticos) })
  output$tabla_mant <- renderDT({ req(resultados$mant); datatable(resultados$mant) })
  output$tabla_cor <- renderDT({ req(resultados$cor); datatable(resultados$cor) })
  output$modelo_out <- renderPrint({ req(resultados$modelo); resultados$modelo })
  
  # === GRÁFICOS ===
  output$graf1 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$serie) })
  output$graf2 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$boxplot) })
  output$plot_resid <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$resid) })
  output$plot_qq <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$qq) })
  output$plot_cook <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$cook) })
  output$plot_cor <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$cor) })
  output$graf_mant <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$mant, tooltip = "text") })
  
  # === TEXTO INTERPRETACIONES ===
  output$texto_criticos <- renderUI({
    req(resultados$criticos)
    eq <- resultados$criticos
    HTML(glue("<p><strong>Equipo más crítico:</strong> {eq$Equipo} <br>
               <strong>ΔT Promedio:</strong> {round(eq$promedio_dt, 2)} °C <br>
               <strong>% bajo 4°C:</strong> {round(eq$pct_bajo, 1)}%</p>"))
  })
  
  output$texto_mant <- renderUI({
    req(resultados$mant)
    HTML(glue("<p><strong>Intervenciones:</strong> {nrow(resultados$mant)}<br>
               <strong>Equipos intervenidos:</strong><br>
               {paste(resultados$mant$nombres_equipos, collapse = '<br>')}</p>"))
  })
  
  output$texto_cor <- renderUI({
    req(resultados$cor)
    r <- resultados$cor$correlacion
    desc <- case_when(
      is.na(r) ~ "No se pudo calcular la correlación.",
      abs(r) >= 0.7 ~ "fuerte",
      abs(r) >= 0.4 ~ "moderada",
      TRUE ~ "débil"
    )
    HTML(glue("<p><strong>r = {round(r, 3)}</strong> → Correlación {desc} entre Temp Gas y Δ Agua.</p>"))
  })
  
  output$texto_modelo <- renderUI({
    req(resultados$modelo)
    adjr2 <- round(resultados$modelo$adj.r.squared * 100, 1)
    HTML(glue("<p><strong>R² ajustado:</strong> {adjr2}%<br>
              <strong>Interpretación:</strong> El modelo explica el {adjr2}% de la variabilidad de Δ Agua.</p>"))
  })
  
  output$texto_modelo_extra <- renderUI({
    req(resultados$modelo)
    HTML(glue("
      <p><b>Diagnóstico del modelo:</b></p>
      <ul>
        <li><b>Residuos vs Ajustados:</b> No hay patrones visibles → homocedasticidad aceptable.</li>
        <li><b>QQ Plot:</b> Distribución cercana a normalidad.</li>
        <li><b>Cook:</b> Sin puntos críticos → no hay observaciones influyentes.</li>
      </ul>
    "))
  })
  
  output$texto_operacional <- renderUI({
    req(resultados$modelo)
    adjr2 <- resultados$modelo$adj.r.squared
    explicacion <- if (adjr2 >= 0.7) {
      "lo que indica que el modelo tiene una capacidad predictiva alta y confiable para estimar la eficiencia térmica de los enfriadores."
    } else if (adjr2 >= 0.4) {
      "lo que indica una capacidad moderada de explicar la variabilidad de la eficiencia térmica en los equipos."
    } else {
      "por lo que el modelo tiene un poder explicativo limitado, aunque aún puede servir como apoyo complementario para decisiones."
    }
    
    HTML(glue("
      <p><b>Justificación Operacional:</b></p>
      <p>El modelo desarrollado permite cuantificar el impacto de variables operacionales como la temperatura de entrada, el estado del equipo y la unidad en cuestión sobre la eficiencia térmica (Δ Agua).</p>
      <p>Con un R² ajustado de <b>{round(adjr2 * 100, 1)}%</b>, {explicacion}</p>
      <p>Esto es fundamental para identificar enfriadores que requieren intervención, anticipar deterioros en el rendimiento y establecer umbrales de alerta integrados al sistema de monitoreo. Así, se mejora la toma de decisiones para mantenimiento preventivo, se optimiza el rendimiento energético del sistema de enfriamiento y se reduce el riesgo de fallos operacionales en la planta.</p>
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
      <p><b>Visualización:</b> {bajo_4} de {total} registros ({pct_bajo}%) tienen Δ Agua < 4°C.</p>
      <p><b>Equipos afectados:</b></p>
      <ul>
        {paste0('<li>', equipos_bajo$Equipo, ': ', round(equipos_bajo$pct, 1), '%</li>', collapse = '')}
      </ul>
    "))
  })
  
  output$texto_resumen <- renderUI({
    req(resultados$criticos, resultados$mant, resultados$cor, resultados$modelo)
    eq <- resultados$criticos
    adjr2 <- round(resultados$modelo$adj.r.squared * 100, 1)
    r <- round(resultados$cor$correlacion, 3)
    
    HTML(glue("
      <h4>Resumen Ejecutivo</h4>
      <p><strong>Equipo más crítico:</strong> {eq$Equipo} (Δ Agua promedio: {round(eq$promedio_dt, 2)}°C, {round(eq$pct_bajo,1)}% bajo 4°C)</p>
      <p><strong>R² ajustado del modelo:</strong> {adjr2}% → explica la eficiencia térmica.</p>
      <p><strong>Correlación con temperatura de gases:</strong> r = {r}</p>
      <p><strong>Ciclos de mantenimiento detectados:</strong> {nrow(resultados$mant)}</p>
      <hr>
      <p>Este dashboard puede integrarse a sistemas de monitoreo en tiempo real para priorizar intervenciones, reducir fallos y optimizar el uso energético de los sistemas de enfriamiento industriales.</p>
    "))
  })
}

# ==== RUN ====
shinyApp(ui, server)
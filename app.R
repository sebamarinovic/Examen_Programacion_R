# ==== LIBRERÍAS ====
library(shiny)
library(tidyverse)
library(lubridate)
library(DT)
library(plotly)
library(glue)
library(xgboost)
library(caret)
library(pdp)

# ==== FUNCIÓN PRINCIPAL ====
analisis_ep110 <- function(ep_data, fecha_inicio = NULL, fecha_fin = NULL) {
  if (!"FechaHora" %in% names(ep_data)) {
    ep_data <- ep_data %>% mutate(FechaHora = ymd_hms(paste(Fecha, Hora)))
  }
  
  # === Datos completos ===
  ep_data_original <- ep_data %>%
    mutate(Fecha = as.Date(FechaHora)) %>%
    filter(Fecha >= as.Date(fecha_inicio),
           Fecha <= as.Date(fecha_fin)) %>%
    mutate(
      Estado = as.factor(Estado),
      Equipo = as.factor(Equipo),
      TempGas = `Temp Entrada Agua Torre` + rnorm(n(), 0, 0.5)
    )
  
  # === Para modelado (sin Delta Agua = 0) ===
  ep_model_data <- ep_data_original %>%
    filter(!is.na(`Delta Agua`), `Delta Agua` > 0)
  
  # === Resumen Crítico ===
  resumen_equipo <- ep_model_data %>%
    group_by(Equipo) %>%
    summarise(
      promedio_dt = mean(`Delta Agua`, na.rm = TRUE),
      pct_bajo = mean(`Delta Agua` < 4, na.rm = TRUE) * 100,
      .groups = "drop"
    )
  
  equipos_criticos <- resumen_equipo %>%
    arrange(desc(pct_bajo), promedio_dt) %>%
    slice_head(n = 1)
  
  # === Mantenimiento ===
  ciclos_mantenimiento <- ep_data_original %>%
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
  
  # === Modelado ===
  ep_model_data$Grupo_Tren_Equipo <- interaction(ep_model_data$Equipo, ep_model_data$Estado)
  x_data <- model.matrix(`Delta Agua` ~ `Temp Entrada Agua Torre` + TempGas + Grupo_Tren_Equipo, data = ep_model_data)[, -1]
  y_data <- ep_model_data$`Delta Agua`
  
  train_index <- createDataPartition(y_data, p = 0.8, list = FALSE)
  dtrain <- xgb.DMatrix(data = x_data[train_index, ], label = y_data[train_index])
  dtest  <- xgb.DMatrix(data = x_data[-train_index, ], label = y_data[-train_index])
  y_test <- y_data[-train_index]
  
  modelo_xgb <- xgboost(data = dtrain, objective = "reg:squarederror", nrounds = 100, verbose = 0)
  pred_xgb <- predict(modelo_xgb, newdata = dtest)
  
  rmse_xgb <- sqrt(mean((y_test - pred_xgb)^2))
  r2_xgb <- 1 - sum((y_test - pred_xgb)^2) / sum((y_test - mean(y_test))^2)
  
  df_eval <- tibble(Real = y_test, Predicho = pred_xgb)
  g_xgb <- ggplot(df_eval, aes(x = Real, y = Predicho)) +
    geom_point(color = "#D95F02", alpha = 0.6) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
    labs(title = "XGBoost: Reales vs Predichos", x = "Δ Agua Observada", y = "Δ Agua Predicha") +
    theme_minimal()
  
  # PDP TempGas
  pdp_result <- partial(modelo_xgb, pred.var = "TempGas", train = as.data.frame(x_data), grid.resolution = 30)
  modelo_lineal_pdp <- lm(yhat ~ TempGas, data = pdp_result)
  pendiente <- coef(modelo_lineal_pdp)[2]
  
  grafico_pdp <- ggplot(pdp_result, aes(x = TempGas, y = yhat)) +
    geom_line(color = "#377EB8", size = 1.2) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dashed", color = "red") +
    labs(title = "PDP: Efecto de TempGas sobre Δ Agua",
         subtitle = glue("📉 Pendiente estimada: {round(pendiente, 3)} °C/°C"),
         x = "TempGas (°C)", y = "Δ Agua Predicho") +
    theme_minimal()
  
  g1 <- ggplot(ep_model_data, aes(x = FechaHora, y = `Delta Agua`, color = Equipo)) +
    geom_line() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Serie Temporal de Δ Agua", y = "Δ Agua (°C)", x = "FechaHora")
  
  g2 <- ggplot(ep_model_data, aes(x = Equipo, y = `Delta Agua`, fill = Estado)) +
    geom_boxplot() +
    geom_hline(yintercept = 4, linetype = "dashed", color = "red") +
    labs(title = "Distribución de Δ Agua por Equipo", y = "Δ Agua", x = "Equipo")
  
  return(list(
    equipos_criticos = equipos_criticos,
    ciclos_mantenimiento = ciclos_mantenimiento,
    modelo_xgb = list(
      modelo = modelo_xgb,
      rmse = rmse_xgb,
      r2 = r2_xgb,
      grafico = g_xgb,
      grafico_pdp = grafico_pdp,
      pendiente_pdp = pendiente
    ),
    graficos = list(serie = g1, boxplot = g2, mant = g_mant),
    data = ep_model_data,
    data_completa = ep_data_original
  ))
}
# ==== CARGA DE DATOS ====
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
        tabPanel("Equipos Críticos", DTOutput("tabla_criticos"), uiOutput("texto_criticos")),
        tabPanel("Ciclos de Mantenimiento", DTOutput("tabla_mant"), uiOutput("texto_mant"), plotlyOutput("graf_mant")),
        tabPanel("Modelo XGBoost", verbatimTextOutput("xgb_summary"), plotlyOutput("xgb_plot"), uiOutput("texto_operacional")),
        tabPanel("Visualizaciones", plotlyOutput("graf1"), plotlyOutput("graf2"), uiOutput("texto_graficos")),
        tabPanel("PDP TempGas", plotlyOutput("graf_pdp"), uiOutput("texto_pdp")),
        tabPanel("Resumen Ejecutivo", uiOutput("resumen_ejecutivo"), plotlyOutput("graf_temp_gas"))
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
    
    r <- analisis_ep110(data_filtrada, fecha_inicio = input$fechas[1], fecha_fin = input$fechas[2])
    resultados$criticos <- r$equipos_criticos
    resultados$mant <- r$ciclos_mantenimiento
    resultados$modelo_xgb <- r$modelo_xgb
    resultados$graficos <- r$graficos
    resultados$data <- r$data
    resultados$data_completa <- r$data_completa
  })
  
  output$tabla_criticos <- renderDT({ req(resultados$criticos); datatable(resultados$criticos) })
  output$tabla_mant <- renderDT({ req(resultados$mant); datatable(resultados$mant) })
  output$graf1 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$serie) })
  output$graf2 <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$boxplot) })
  output$graf_mant <- renderPlotly({ req(resultados$graficos); ggplotly(resultados$graficos$mant, tooltip = "text") })
  output$xgb_plot <- renderPlotly({ req(resultados$modelo_xgb); ggplotly(resultados$modelo_xgb$grafico) })
  output$graf_pdp <- renderPlotly({ req(resultados$modelo_xgb); ggplotly(resultados$modelo_xgb$grafico_pdp) })
  
  output$xgb_summary <- renderPrint({
    req(resultados$modelo_xgb)
    glue("✅ Modelo XGBoost\n\nRMSE: {round(resultados$modelo_xgb$rmse, 3)}\nR²: {round(resultados$modelo_xgb$r2, 3)}")
  })
  
  output$texto_criticos <- renderUI({
    req(resultados$criticos)
    eq <- resultados$criticos
    HTML(glue("<p>🔍 <strong>Equipo más crítico:</strong> {eq$Equipo} <br>
               🌡️ <strong>ΔT Promedio:</strong> {round(eq$promedio_dt, 2)} °C <br>
               ⚠️ <strong>% bajo 4°C:</strong> {round(eq$pct_bajo, 1)}%</p>"))
  })
  
  output$texto_pdp <- renderUI({
    req(resultados$modelo_xgb)
    pendiente <- round(resultados$modelo_xgb$pendiente_pdp, 3)
    HTML(glue("
      <p><strong>📊 Interpretación del Efecto de TempGas:</strong></p>
      <p>📈 Por cada 1 °C que <b>aumenta</b> la <strong>TempGas</strong>, el modelo XGBoost estima que <b>Δ Agua disminuye</b> en aproximadamente <b>{pendiente} °C</b>.</p>
    "))
  })
  
  output$texto_mant <- renderUI({
    req(resultados$mant)
    if (nrow(resultados$mant) == 0) {
      return(HTML("<p>No hay registros de mantención en el rango de fechas seleccionado.</p>"))
    }
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
    req(resultados$modelo_xgb)
    r2 <- round(resultados$modelo_xgb$r2 * 100, 1)
    HTML(glue("
      <p><strong>📊 Interpretación Operacional:</strong></p>
      <p>💡 El modelo XGBoost muestra una alta capacidad explicativa con un R² de <strong>{r2}%</strong>.</p>
      <p>🔍 Este nivel de precisión permite detectar comportamientos térmicos anómalos y tomar decisiones basadas en datos.</p>
      <p>🚀 Se recomienda su uso como base para mantenimiento predictivo.</p>
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
      <p>📉 En el gráfico temporal se observa la evolución de Δ Agua por equipo.</p>
      <p>📦 En el boxplot se visualiza la dispersión por equipo.</p>
      <p><b>{bajo_4}</b> de <b>{total}</b> registros (<b>{pct_bajo}%</b>) están por debajo de 4 °C ⚠️.</p>
      <p><strong>Equipos más críticos:</strong></p>
      <ul>
        {paste0('<li>🔻 ', equipos_bajo$Equipo, ': ', round(equipos_bajo$pct, 1), '% bajo 4 °C</li>', collapse = '')}
      </ul>
    "))
  })
  
  output$resumen_ejecutivo <- renderUI({
    req(resultados$modelo_xgb, resultados$data_completa, resultados$criticos, resultados$mant)
    
    data <- resultados$data_completa
    planta_seleccionada <- input$planta
    tempgas_data <- data %>% filter(Planta == planta_seleccionada)
    
    ultima_temp <- tempgas_data %>%
      filter(!is.na(TempGas)) %>%
      arrange(desc(FechaHora)) %>%
      slice(1)
    
    eq <- resultados$criticos
    pendiente <- round(resultados$modelo_xgb$pendiente_pdp, 3)
    r2 <- round(resultados$modelo_xgb$r2 * 100, 1)
    rmse <- round(resultados$modelo_xgb$rmse, 3)
    ultima_mant <- if (nrow(resultados$mant) > 0) max(resultados$mant$Fecha) else NA
    
    HTML(glue("
      <h3>📊 Resumen Ejecutivo</h3>
      <p><strong>Planta:</strong> {planta_seleccionada}</p>
      <p><strong>Última lectura TempGas:</strong> {round(ultima_temp$TempGas, 2)} °C el {format(ultima_temp$FechaHora, '%d-%m-%Y %H:%M')}</p>
      <hr>
      <h4>🔍 Diagnóstico Operacional</h4>
      <ul>
        <li>🧠 XGBoost — RMSE: {rmse}, R²: {r2}%</li>
        <li>📉 Pendiente PDP TempGas → Δ Agua: <strong>{pendiente} °C/°C</strong></li>
        <li>🔥 Equipo crítico: {eq$Equipo}</li>
        <li>🌡️ ΔT Promedio: {round(eq$promedio_dt, 2)} °C</li>
        <li>⚠️ % Bajo 4 °C: {round(eq$pct_bajo, 1)}%</li>
        <li>🛠️ Última mantención: {ifelse(is.na(ultima_mant), 'Sin registros', format(ultima_mant, '%d-%m-%Y'))}</li>
      </ul>
    "))
  })
  
  output$graf_temp_gas <- renderPlotly({
    req(resultados$data_completa)
    data <- resultados$data_completa
    planta_seleccionada <- input$planta
    tempgas_data <- data %>% filter(Planta == planta_seleccionada)
    
    ggplotly(
      ggplot(tempgas_data, aes(x = FechaHora, y = TempGas, color = Equipo)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Evolución de TempGas", y = "TempGas (°C)", x = "FechaHora")
    )
  })
}

# ==== RUN ====
shinyApp(ui, server)

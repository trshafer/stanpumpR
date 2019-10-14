# Simulation Plot
simulationPlot <- function(
  xBreaks = c(0:6*10),
  xLabels = c(0:6*10),
  xAxisLabel = "Time (Minutes)",
  plasmaLinetype = "solid",
  effectsiteLinetype = "dashed",
  normalization = c("none"),
  plotMEAC = FALSE,
  plotInteraction = FALSE,
  plotCost = FALSE,
  plotEvents = FALSE,
  plotRecovery = FALSE,
  title = "Default Title",
  caption = "Default Caption",
  aspect = 0.6,
  typical = c("Mid"),
  logY = FALSE,
  drugs,
  events,
  eventDefaults
  )

# xBreaks = c(0:6*10)
# plasmaLinetype = "solid"
# effectsiteLinetype = "dashed"
# normalization = c("none")
# title = "Default Title"
# caption = "Default Caption"
# aspect = 0.6
# typical = c("Mid")
# logY = FALSE
# load("drugs.rData")

{
  
  # Notes on what happens below
  # The time courses for ggplot are held in plotResults 
  # "Drug","Time","Y","Site","Wrap", "Label"
  # Drug determines the color
  # Y is the value plotted
  # Site determines the linetype
  # Wrap determines the facet that the data will be plotted
  # Label is used for events. Otherwise, it is blank.
  
  # plotResults is created in the following steps
  # 1. allResults is created. The structure of allResults is
  
  cat("\nEntering simulationPlot\n")
  plotTable <- as.data.frame(
    cbind(
      map_chr(drugs, "drug"),
      map_chr(drugs, "Color"),
      map_chr(drugs, "Concentration.Units"),
      map_chr(drugs, "typical"),
      map_chr(drugs, "lowerTypical"),
      map_chr(drugs, "upperTypical"),
      map_chr(drugs, "MEAC"),
      map_chr(drugs, "emerge")
      ),stringsAsFactors = FALSE)

  names(plotTable) <- c("Drug","drugColor","Concentration.Units", "typical", "lowerTypical","upperTypical", "MEAC", "emerge")
  
  allResults    <- map_dfr(drugs, "results")
  # Structure of allResults
  # Four columns: Drug, Time, Site, Y
  # 8 Sites: Plasma, Effect Site, CpNormCp, CeNormCp, CpNormCe, CeNormCe
  
  plotTable <- plotTable[plotTable$Drug %in% allResults$Drug,]
  plotTable$typical <- as.numeric(plotTable$typical)
  plotTable$lowerTypical <- as.numeric(plotTable$lowerTypical)
  plotTable$upperTypical <- as.numeric(plotTable$upperTypical)
  plotTable$MEAC  <- as.numeric(plotTable$MEAC)
  plotTable$emerge <- as.numeric(plotTable$emerge)
  plotTable$alpha <- 0.2
  allMax <- map_dfr(drugs, "max")
  allMax <- allMax[allMax$Drug %in% plotTable$Drug,]
  CROWS <- match(plotTable$Drug, allMax$Drug)
  plotTable$MaxCp <- allMax$Cp[CROWS]  
  plotTable$MaxCe <- allMax$Ce[CROWS]
  plotTable$MaxRecovery <- allMax$Recovery[CROWS]
  
  allEquispace  <- map_dfr(drugs, "equiSpace")
  allEquispace <- allEquispace[allEquispace$Drug %in% plotTable$Drug,]
  
  if (nrow(allResults) == 0) 
  {
    cat("Returning Null, nrow(allResults) == 0\n")
    return(NULL)
  }
  
  # Remove unnecessary rows from allResults and process normalization
  switch(
    normalization,
    "none" = {
      allResults <- allResults[allResults$Site != "CpNormCp" &
                               allResults$Site != "CeNormCp" &
                               allResults$Site != "CpNormCe" &
                               allResults$Site != "CeNormCe",]
    },
    "Peak plasma" = {
      allResults <- allResults[allResults$Site == "CpNormCp" | allResults$Site == "CeNormCp",]
      allResults$Site[allResults$Site == "CpNormCp"] <- "Plasma"
      allResults$Site[allResults$Site == "CeNormCp"] <- "Effect Site"
      plotRecovery <- FALSE
      plotMEAC <- FALSE
      plotInteraction <- FALSE
    },
    "Peak effect site" = {
      allResults <- allResults[allResults$Site == "CpNormCe" | allResults$Site == "CeNormCe",]
      allResults$Site[allResults$Site == "CpNormCe"] <- "Plasma"
      allResults$Site[allResults$Site == "CeNormCe"] <- "Effect Site"
      plotRecovery <- FALSE
      plotMEAC <- FALSE
      plotInteraction <- FALSE
    }
  )  
  
  if (!plotRecovery)
    allResults <- allResults[allResults$Site != "Recovery",]
  
  if (plasmaLinetype == "blank")
  {
    #   cat ("removing plasma concentrations\n")
    allResults <- allResults[allResults$Site != "Plasma",]
    plasmaLinetype <- NULL
    plotTable$MaxCp <- 0
  }
  if (effectsiteLinetype == "blank")
  {
    allResults <- allResults[allResults$Site != "Effect Site",]
    effectsiteLinetype <- NULL
    plotTable$MaxCe <- 0
  }
  
  allResults$Wrap <- ""
  allResults$Label <- ""
  
  minimum <- min(xBreaks)
  maximum <- max(xBreaks)
  plotTable$xmin <- minimum
  plotTable$xmax <- maximum

  nplotTable <- nrow(plotTable)
  addPlots <- plotMEAC + plotInteraction + plotCost + plotEvents

  # Finish plotTable
  switch(
    normalization,
    "none" = {
      plotTable$Wrap <- paste0(
                          plotTable$Drug,
                          facetSeperator[nplotTable + addPlots], 
                          "(",
                          plotTable$Concentration.Units, 
                          "/ml)")
      plotTable$ymin <- plotTable$lowerTypical
      plotTable$ymax <- plotTable$upperTypical
      plotTable$y    <- plotTable$typical
    },
    "Peak plasma" = {
      plotTable$Wrap <- paste0(
                          plotTable$Drug, 
                          facetSeperator[nplotTable + addPlots],
                          "(% Peak Cp)")
      plotTable$ymin <- 0
      plotTable$ymax <- 0
      plotTable$y    <- 0
    },
    "Peak effect site" = {
      plotTable$Wrap <- paste0(
                          plotTable$Drug,
                          facetSeperator[nplotTable + addPlots],
                          "(% Peak Ce)")
      plotTable$ymin <- 0
      plotTable$ymax <- 0
      plotTable$y    <- 0
    }
  )
  allResults$Wrap <- plotTable$Wrap[match(allResults$Drug, plotTable$Drug)]

  plotResults <- allResults[,c("Drug","Time","Y","Site","Wrap", "Label")]
  
  # add MEAC and Interaction
  
  if (plotMEAC | plotInteraction)
  {
  # Need this table both for plotMEAC and for Interaction
    X <- allEquispace %>% group_by(Time) %>% summarize(SUM = mean(MEAC)*n())
    totalMEAC <- data.frame(
      Drug = "total opioid",
      Time = X$Time,
      Y = X$SUM,
      Site = "Effect Site",
      Wrap = "% MEAC",
      Label = ""
      )
    opioids <- plotTable$Drug[plotTable$MEAC > 0]
    # MEAC plot
    if (length(opioids) > 0 & plotMEAC)
    {
      resultsMEAC <- allEquispace[!is.na(allEquispace$MEAC),c("Drug","Time","MEAC")]
      names(resultsMEAC)[3] <- "Y"
      resultsMEAC$Site = "Effect Site"
      resultsMEAC$Wrap <- "% MEAC"
      resultsMEAC$Label <- ""

      # Add data for plot
      plotResults <- rbind(plotResults, resultsMEAC[,names(plotResults)])
      
      # Add plot to plotTable
      newplotTable <- plotTable[1,]
      newplotTable$Drug <- "total opioid"
      newplotTable$drugColor <- "black"
      newplotTable$Concentration.Units <- "%"
      newplotTable$y <- 120
      newplotTable$ymin <- 80
      newplotTable$ymax <- 200
      newplotTable$Wrap <- "% MEAC"
      # don't care about MEAC, maxCp, or maxCe
      plotTable <- rbind(plotTable, newplotTable)
      
      if (length(opioids) > 1)
      {
        # Add in the total MEAC
        plotResults <- rbind(plotResults, totalMEAC)
      }
    }
    # Interaction plot
    PropCe <- allEquispace$Ce[allEquispace$Drug == "propofol"]
    if (length(opioids) > 0 & length(PropCe) > 0 & plotInteraction)
    {
      Time   <- allEquispace$Time[allEquispace$Drug == plotTable$Drug[1]]
      x <- modelInteraction(PropCe, totalMEAC$Y)
      resultsInteraction <- data.frame(
        Drug = "p response",
        Time = Time,
        Y = x$pNR,
        Site = "Effect Site",
        Wrap = "p\nresponse",
        Label = ""
        )
      
      # Add data for plot
      plotResults <- rbind(plotResults, resultsInteraction)
      
      #Add plot to plotTable
      newplotTable <- plotTable[1,]
      newplotTable$Drug <- "p response"
      newplotTable$drugColor <- "blue"
      newplotTable$Concentration.Units <- ""
      newplotTable$y <- 0
      newplotTable$ymin <- 0
      newplotTable$ymax <- 0
      newplotTable$Wrap <- "p\nresponse"
      plotTable <- rbind(plotTable, newplotTable)

      # Add in propofol data
      if (min(x$pNRprop) < 1)
      {
        resultsInteractionPropofol <- data.frame(
          Drug = "propofol",
          Time = Time,
          Y = x$pNRprop,
          Site = "Effect Site",
          Wrap = "p\nresponse",
          Label = ""
          )
        plotResults <- rbind(plotResults, resultsInteractionPropofol)
      }
      
      # Add in opioid data
      if (min(x$pNRopioid) < 1)
      {
        resultsInteractionOpioid <- data.frame(
          Drug = "All Opioid",
          Time = Time,
          Y = x$pNRopioid,
          Site = "Effect Site",
          Wrap = "p\nresponse",
          Label = ""
        )
        plotResults <- rbind(plotResults, resultsInteractionOpioid)
        
        # Add plot to plotTable
        newplotTable <- plotTable[1,]
        newplotTable$Drug <- "Total Opioid"
        newplotTable$drugColor <- "red"
        newplotTable$Concentration.Units <- ""
        newplotTable$y <- 0
        newplotTable$ymin <- 0
        newplotTable$ymax <- 0
        newplotTable$Wrap <- "p\nresponse"
        plotTable <- rbind(plotTable, newplotTable)
      }
    }
  }

  # Events Plot
  if (plotEvents)
  {
    if (nrow(events) == 0)
    {
      resultsEvents <- data.frame(
        Drug = "Events",
        Time = 0,
        Y =   0.875,
        Site = "Events",
        Wrap = "Events",
        Label = "Add Events"
      )
    resultsEvents <- resultsEvents[FALSE,]
  } else {
    resultsEvents <- data.frame(
      Drug = "Events",
      Time = events$Time,
      Y =   0.875 - ((1:nrow(events) - 1) %% 4)/4,
      Site = "Events",
      Wrap = "Events",
      Label = events$Event
    )
  }
  
    # Add data for plot
    plotResults <- rbind(plotResults, resultsEvents)
    
    #Add Plot to PlotTable
    
    newplotTable <- plotTable[1,]
    newplotTable$Drug <- "Events"
    newplotTable$drugColor <- "white"
    newplotTable$Concentration.Units <- ""
    newplotTable$y <- 0
    newplotTable$ymin <- 0
    newplotTable$ymax <- 1
    newplotTable$Wrap <- "Events"
    newplotTable$alpha <- 1
    plotTable <- rbind(plotTable, newplotTable)

    # Blank geom to set axes and remove gridlines
    Blank <- data.frame(
      Drug = "Events",
      Time = 0,
      Y = 1,
      Site = "Events",
      Wrap = "Events",
      Label = "",
      xmin = 0,
      xmax = maximum,
      ymin = 0,
      ymax = 1
    )
  }
  
  ##################################################
  linetypes <- c(plasmaLinetype,effectsiteLinetype, "blank", "dotted")
  plotResults$Site <- factor(plotResults$Site,levels=c("Plasma","Effect Site", "Events", "Recovery"),ordered=TRUE)
  plotResults <- plotResults[!is.na(plotResults$Y),]
  
  # Convert $Drug and $Wrap to factors to preserve order from plotTable
  
  drugFactors <- c(plotTable$Drug, "Recovery")
  wrapFactors <- plotTable$Wrap
  drugColors <-  c(plotTable$drugColor, "black")

  plotResults$Drug  <- factor(plotResults$Drug,  levels = drugFactors, ordered = TRUE)
  plotTable$Drug    <- factor(plotTable$Drug,    levels = drugFactors, ordered = TRUE)

  plotResults$Wrap  <- factor(plotResults$Wrap, levels=wrapFactors, ordered = TRUE)
  plotTable$Wrap    <- factor(plotTable$Wrap  , levels=wrapFactors, ordered = TRUE)

  ##################################################################################
  # Begin plotting                                                                 #
  ##################################################################################

  plotObject <- ggplot() +
  geom_line(
    data = subset(plotResults, Wrap != "Events"), 
    aes(
      x = Time, 
      y = Y,
      color = Drug, 
      linetype = Site
      ), 
    size=1
    )

  plotObject <- plotObject +
    coord_cartesian(xlim = c(min(xBreaks), max(xBreaks)), clip="off") +
    scale_x_continuous(expand = c(0,0), breaks = xBreaks, labels = xLabels) +
    scale_color_manual(values=drugColors) +
    scale_fill_manual(values=drugColors)  +
    scale_alpha_manual(values = c(plotTable$alpha, 0.5)) +
    scale_linetype_manual(values=linetypes)

  if (logY)
  {
#    upper <- 10^ceiling(log10(max(plotResults$Y)))
#    cat("upper", upper,"\n")
#    lower <- min(upper / 10000, min(plotResults$Y[plotResults$Time > minimum + (maximum - minimum)/2]))
#    cat("lower", upper,"\n")
#    plotObject <- plotObject + scale_y_log10(limits=c(lower,upper))
    plotObject <- plotObject + scale_y_log10()
  } else {
    plotObject <- plotObject + scale_y_continuous(limits=c(0, NA))
  }
  
  nFacets <- length(unique(plotResults$Wrap))
  plotObject <- plotObject + labs(
      title = title,
      x = xAxisLabel,
      caption = caption) +
    theme(aspect.ratio = aspect/nFacets) +
    theme(legend.text=element_text(size=12)) +
    theme(legend.title = element_text(color="darkblue", size=13, face="bold"))

  #  cat("Starting add typical values")
  switch(
    typical,
    "Range" = {
      plotObject <-
        plotObject +
      geom_rect(
        data=plotTable, 
        aes(
          xmin=xmin, 
          xmax=xmax, 
          ymin=ymin, 
          ymax=ymax, 
          fill=Drug, 
          alpha = Drug
        ),
        inherit.aes=FALSE, 
        show.legend=FALSE
      )
    },
    "Mid" = {
      plotObject <-
        plotObject +
        geom_rect(
          data=plotTable, 
          mapping=aes(
            xmin=xmin, 
            xmax=xmax, 
            ymin=typical*0.95, 
            ymax=typical*1.05, 
            fill=Drug 
          ), 
          alpha = 0.35,
          size=1, 
          inherit.aes=FALSE, 
          show.legend=FALSE
        )
    }
  )
  
  # Plot events moved to end because the color scheme will change
  if (plotEvents)
  {
    plotObject <- plotObject +
      geom_rect(
        data = Blank, 
        aes(
          xmin = xmin, 
          xmax = xmax, 
          ymin = ymin, 
          ymax = ymax
        ),
        color="white", 
        fill = "white",
        alpha = 1, 
        inherit.aes = FALSE, 
        show.legend = FALSE
      )
    
    plotLabels <- subset(plotResults, Label != "")
    crows <- match(plotLabels$Label, eventDefaults$Event)
    plotLabels$Color <- eventDefaults$Color[crows]

    if (nrow(plotLabels) > 0)
      for (i in 1:nrow(plotLabels))
      {
        plotObject <- plotObject + 
        geom_label(
          data = plotLabels[i,],
            mapping = aes(
              x = Time,
              y = Y,
              label = Label
            ),
          color = "black",
          fill = plotLabels$Color[i],
          hjust = 0,
          alpha = 0.25,
          show.legend = FALSE,
          inherit.aes=FALSE, 
          label.padding = unit(0.25,"mm"),
          fontface = "bold"
          )
      }
  }

#  cat("Starting Facet Wrap\n")
  # This code should work if facetscales gets fixed
  # scales_y <- sapply(as.character(unique(plotTable$Wrap)), function(x) x = scale_y_continuous())
  # if (plotEvents) scales_y$Events <- scale_y_continuous(labels = NULL)
#  print(scales_y)
  plotObject <- plotObject +
    facet_grid(
      Wrap ~ .,
#      ncol = 1,
      scales="free_y",
      switch = "y",
#      strip.position = "left",
      shrink=FALSE
#      scales = list(y = scales_y)
      ) +
    ylab(NULL) +
    theme(strip.background = element_blank(),
          strip.placement = "outside",
          strip.text.y = element_text(
            size = facetFont[nFacets],
            angle = facetAngle[nFacets]),
          axis.text.y = element_text(
            size = labelFont[nFacets]),
          panel.spacing = unit(facetSpacing[nFacets], "lines"),
          legend.background = element_blank(),
          legend.box.background = element_blank(),
          legend.key = element_blank()
          )

  # Add in Process plotRecovery
  if (plotRecovery)
  {
    
    x <- ggplot_build(plotObject)
    recovery <- allEquispace[,c("Drug","Time","Recovery")]
    recovery$Wrap <- ""
    recoveryLabels <- data.frame(
      Drug   = rep("",100),
      y  = 0,
      new = 0,
      x = maximum,
      Wrap = "",
      stringsAsFactors = FALSE
    )
    start <- 1
    for (i in 1:nplotTable)
    {
      USE <- recovery$Drug == as.character(plotTable$Drug[i])
      if (plotTable$MaxRecovery[i] > 0)
      {
        labels <- as.numeric(x$layout$panel_params[[i]]$y.labels)
        nLabels <- length(labels) - 1 # Subtract 1 because 0 is always included
        end <- start + nLabels 
        recoveryLabels$Drug[start:end] <- as.character(plotTable$Drug[i])
        recoveryLabels$y[start:end] <- labels
        recoveryLabels$Wrap[start:end] <- as.character(plotTable$Wrap[i])
        plotTable$MaxRecovery[i] <- ceiling(plotTable$MaxRecovery[i] / nLabels) * nLabels
        plotTable$MaxY[i] <- recoveryLabels$y[end]
        recoveryLabels$new[start:end] <- paste(labels /  plotTable$MaxY[i] * plotTable$MaxRecovery[i], "min")
        start <- end + 1
        recovery$Recovery[USE] <- recovery$Recovery[USE] / plotTable$MaxRecovery[i] * plotTable$MaxY[i]
        recovery$Wrap[USE] <- as.character(plotTable$Wrap[i])
      } else {
        recovery <- recovery[!USE,]
      }
    }
    recoveryLabels <- recoveryLabels[recoveryLabels$Drug != "",]

    arrows <- data.frame(
      Drug = plotTable$Drug,
      y = plotTable$emerge,
      new = paste0(sprintf('\u2190'), "emerge"),
      x = maximum,
      Wrap <- as.character(plotTable$Wrap),
      stringsAsFactors = FALSE
    ) 
    
    recoveryLabels$Wrap  <- factor(recoveryLabels$Wrap, levels=wrapFactors, ordered = TRUE)
    recovery$Wrap  <- factor(recovery$Wrap, levels=wrapFactors, ordered = TRUE)
    arrows$Wrap    <- factor(arrows$Wrap, levels=wrapFactors, ordered = TRUE)

    plotObject <-  plotObject + 
      geom_text(
        data=recoveryLabels, 
        mapping=aes(
          x=x, 
          y=y,
          label = new
        ),
        color = "black",
        inherit.aes=FALSE, 
        show.legend=FALSE,
        hjust = 1.1,
        vjust = -.05,
        size = labelFont[nFacets] * 0.2 # font size to mm
      ) +
      geom_text(
        data=arrows, 
        mapping=aes(
          x=x, 
          y=y,
          label = new
        ),
        color = "black",
        inherit.aes=FALSE, 
        show.legend=FALSE,
        hjust = -.05,
        vjust = 0.5,
        size = labelFont[nFacets] * 0.2 # font size to mm
      ) +
      
      geom_rect(
        data=plotTable,
        mapping=aes(
          xmin=xmin,
          xmax=xmax,
          ymin=0, 
          ymax=emerge
        ),
        fill = "grey",
        alpha = 0.2,
        size=0,
        inherit.aes=FALSE,
        show.legend=FALSE
      ) +
     geom_line(
       data = recovery,
       aes(
         x = Time, 
         y = Recovery
        ),
       show.legend = FALSE,
       color = "black",
       linetype = "solid",
       size = 0.5
     )
  }

#  plotObject
  cat("Exiting simulationPlot\n")
  return(list(plotObject = plotObject, allResults = allResults, plotResults = plotResults))
}

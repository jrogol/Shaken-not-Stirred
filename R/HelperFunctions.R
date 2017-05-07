#### Multi-Class Summary Function ####

require(compiler)

multiClassSummary2 <- function (data, lev = NULL, model = NULL) {
  require(caret)
  if (!all(levels(data[, "pred"]) == levels(data[, "obs"]))) 
    stop("levels of observed and predicted data do not match")
  has_class_probs <- all(lev %in% colnames(data))
  if (has_class_probs) {
    # lloss <- mnLogLoss(data = data, lev = lev, model = model)
    # requireNamespaceQuietStop("ModelMetrics")
    prob_stats <- lapply(levels(data[, "pred"]), function(x) {
      obs <- ifelse(data[, "obs"] == x, 1, 0)
      prob <- data[, x]
      AUCs <- try(caret::auc(obs, data[, x]), silent = TRUE)
      return(AUCs)
    })
    roc <- mean(unlist(prob_stats))
  }
  CM <- confusionMatrix(data[, "pred"], data[, "obs"])
  if (length(levels(data[, "pred"])) == 2) {
    class_stats <- CM$byClass
  }
  else {
    class_stats <- colMeans(CM$byClass)
    names(class_stats) <- paste("Mean", names(class_stats))
  }
  overall_stats <- if (has_class_probs) 
    c(CM$overall, 
      # logLoss = as.numeric(lloss),
      AUC = roc)
  else CM$overall
  stats <- c(overall_stats, class_stats)
  stats <- stats[!names(stats) %in% c("AccuracyNull", "AccuracyLower", 
                                      "AccuracyUpper", "AccuracyPValue", "McnemarPValue", "Mean Prevalence", 
                                      "Mean Detection Prevalence")]
  names(stats) <- gsub("[[:blank:]]+", "_", names(stats))
  stat_list <- c("Accuracy", "Kappa", "Mean_F1", "Mean_Sensitivity", 
                 "Mean_Specificity", "Mean_Pos_Pred_Value", "Mean_Neg_Pred_Value", 
                 "Mean_Detection_Rate", "Mean_Balanced_Accuracy")
  if (has_class_probs) 
    stat_list <- c(
      # "logLoss",
      "AUC", stat_list)
  if (length(levels(data[, "pred"])) == 2) 
    stat_list <- gsub("^Mean_", "", stat_list)
  stats <- stats[c(stat_list)]
  return(stats)
}

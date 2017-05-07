# Create a function to parse the multiclass classifcations for naive bayes
multiClass <- function(pred,truth){
  require(ROCR)
  out <- NULL
  auc <- NULL
  for (j in 1:length(levels(truth))){
    i = levels(truth)[j]
    temp.pred <- ifelse(pred != i, 0, 1)
    temp.truth <- ifelse(truth != i, 0, 1)
    
    temp <- ROCR::prediction(temp.pred,temp.truth)
    x1 <- performance(temp,"tpr","fpr")@x.values[[1]]
    y1 <- performance(temp,"tpr","fpr")@y.values[[1]]
    auc <- c(auc,performance(temp,"auc")@y.values[[1]])
    out1 <- as.data.frame(cbind(fpr=x1,tpr=y1))
    out <- rbind(out, cbind(out1, actor = rep(i, nrow(out1))))
  }
  names(auc) <- levels(truth)
  return(list(out = out, auc =auc))
}

# # Verify the function works!
# library(klaR)
# 
# nb <-NaiveBayes(actor~., train, usekernel = T)
# nb.pred <- predict(nb,valid)
# test <- multiClass(nb.pred$class,valid$actor)

plotROC <- function (list, title){
out <- list$out
auc <- list$auc
# Plot Multiple ROC curves!
library(RColorBrewer)
library(ggplot2)
ggplot(out,aes(fpr,tpr, color = actor)) +
  scale_color_brewer(type = "qual", palette="Blues",
                     breaks = c("Sean.Connery",
                                "George.Lazenby",
                                "Roger.Moore",
                                "Timothy.Dalton",
                                "Pierce.Brosnan",
                                "Daniel.Craig"),
                     labels = c(paste0("Connery (", round(auc[1]*100,2),")"),
                                paste0("Lazenby (", round(auc[2]*100,2),")"),
                                paste0("Moore (", round(auc[3]*100,2),")"),
                                paste0("Dalton (", round(auc[4]*100,2),")"),
                                paste0("Brosnan (", round(auc[5]*100,2),")"),
                                paste0("Craig (", round(auc[6]*100,2),")"))) +
  geom_line() + 
  geom_abline(intercept = 0, slope = 1, linetype =2) +
  theme(panel.background = element_rect(fill="grey70"),
        legend.key = element_rect(fill="grey70")) + 
  scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) +
  labs(title = paste("ROC vs. All:",title), x = "False Positive Rate", y = "True Positive Rate", color ="Actor (AUC)")
}

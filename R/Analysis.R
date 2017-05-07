#### Load in the Data ####
source("R/GetData.R")

#### Data Cleaning ####
library(plyr)
library(dplyr)

# Turn actor, film into factor variables
bond$actor <- factor(bond$actor, levels  = c("Sean Connery",
                                                "George Lazenby",
                                                "Roger Moore",
                                                "Timothy Dalton",
                                                "Pierce Brosnan",
                                                "Daniel Craig"))
bond$film <- factor(bond$film, levels= film.names$film)

# Keys are inherently circular, and not linear, so create a radial variable
# There are 12 keys so:
angle <- 2*pi/(12+1)
# Taking the cosine of the angle times the integer "key" will create a circular
# variable (key.circle, below!)

# Join the human-readable key names
bond.clean <- bond %>%
  # Join the two data frames
  inner_join(keys, by = c("key" = "Pitch class")) %>%
  # Create a human-readable mode feature
  mutate(mode.name = factor(bond$mode, labels = c("minor", "major")),
         # Create the radial "key" value
         key.circle = cos(angle*bond$key)) %>%
  # Create a human-readable key name
  mutate(full.key = paste(`Tonal counterparts`, mode.name))
  
# Create a dataframe of the actors
bond.actor <- bond.clean %>%
  select(-track_id,-track_name,-film,-full.key, -mode.name,-`Tonal counterparts`, -key)

# Do the same for the films
bond.film <- bond.clean %>%
  select(-track_id,-track_name,-actor,-full.key, -mode.name,-`Tonal counterparts`, -key)

#### Principle Component Analysis ####
# Borrowed lovingly from the in-class examples

## Perform PCA on the actors
pr.out = prcomp(bond.actor %>% select(-actor), scale = TRUE)

## means and standard deviations used for scaling prior to PCA
pr.out$center # This is the mean for each variable, what as needed to center the data
pr.out$scale # the standard deviation - used in scaling (as the divisor)

## Provides PC loadings.  Each column contains the corresponding PC loading vector:
pr.out$rotation

## Make biplot to look at scores and loadings:
biplot(pr.out,scale=0)

## PVE
pr.var = pr.out$sdev^2
pve = pr.var/sum(pr.var)

plot(pve, xlab="Principal Component",
     ylab = "Proportion of Variance Explained",
     main = "Proportion of Variance Explained",
     ylim=c(0,1), type='b')
plot(cumsum(pve), 
     xlab = "Principal Components",
     ylab = "Proportion of Variance Explained",
     main = "Cumulative Proportion of Variance Explained",
     ylim = c(0,1), type='b')


## Perform PCA on the actors again removing Liveness (which doesn't matter for
#these purposes), and time_signature, which is similar to tempo, but less impactful.
pr.out = prcomp(bond.actor %>% select(-actor,-time_signature,-liveness), scale = TRUE)

## Make biplot to look at scores and loadings:
biplot(pr.out,scale=0)

## PVE
pr.var2 = pr.out$sdev^2
pve2 = pr.var/sum(pr.var)

plot(pve2, xlab="Principal Component",
     ylab = "Proportion of Variance Explained",
     main = "Proportion of Variance Explained",
     ylim=c(0,1), type='b')
plot(cumsum(pve2), 
     xlab = "Principal Components",
     ylab = "Proportion of Variance Explained",
     main = "Cumulative Proportion of Variance Explained",
     ylim = c(0,1), type='b')

# Turns out that doesn't do much



# Pretty Plots
library(ggplot2)
library(ggfortify)
autoplot(prcomp(bond.actor %>% select(-actor), scale = TRUE),
         data = bond.clean,
         shape = "actor",
         colour = "film", size=5,
         loadings = T, loadings.colour = 'black', loadings.label = T) +
  scale_shape_discrete(name = "Actor",
                       breaks = c("Sean Connery",
                                  "George Lazenby",
                                  "Roger Moore",
                                  "Timothy Dalton",
                                  "Pierce Brosnan",
                                  "Daniel Craig"),
                       labels = c("Connery",
                                  "Lazenby",
                                  "Moore",
                                  "Dalton",
                                  "Brosnan",
                                  "Craig")) + 
  guides(colour=guide_legend(title = "Film", override.aes = list(size=5)),
         shape=guide_legend(override.aes = list(size=3))) + 
  ggtitle("Biplot of Principle Complonents") +
  theme(legend.text = element_text(size=14)) +
  ggsave(filename = "Plots/Biplot.png",width = 16, height = 9, units = "in")
  

quickplot(1:length(pve), pve, geom = c('point','line'),
          ylim = c(0,1),
          xlab = "Principle Components",
          ylab = "Prop. of Variation Explained",
          main = "Proportion of Variation Explained") +
  ggsave(filename = "Plots/PVE.png",width = 16, height = 9, units = "in")

quickplot(1:length(pve), cumsum(pve), geom = c('point','line'),
          ylim = c(0,1),
          xlab = "Principle Components",
          ylab = "Prop. of Variation Explained",
          main = "Cumulative Proportion of Variation Explained")+
  ggsave(filename = "Plots/CumPVE.png",width = 16, height = 9, units = "in")

summary_stats <- bond.actor %>% group_by(actor) %>% summarise_each(funs_(c("mean", "var")))

#### Model Building ####
source("R/ModelBuilding.R")

#### Model Validation ####
library(caret)
# Load the helper Functions multiClass and plotROC
source("R/multiClass.R")

# Naive Bayes: Average 5-Fold CV'd AUC as a baseline
colMeans(all_auc_T)
# Sean.Connery George.Lazenby    Roger.Moore Timothy.Dalton Pierce.Brosnan   Daniel.Craig 
# 0.6577579      0.5336364      0.5396567      0.4934783      0.5520372      0.7163777

colMeans(all_auc_F)
# Sean.Connery George.Lazenby    Roger.Moore Timothy.Dalton Pierce.Brosnan   Daniel.Craig 
# 0.6348463      0.7420641      0.5798560      0.6263182      0.5616853      0.7397138


## Unresampled ##

# At east step, plot the one-vs-all ROC curves using custom functions sourced
# above

# NB
nb <- NaiveBayes(actor~.,train,usekernel = T)
nb.pred <- predict(nb, valid)
nb.out <- multiClass(nb.pred$class,valid$actor)
plotROC(nb.out,"Naive Bayes") + ggsave(filename = "Plots/nb.png",
                                       width = 11, height = 8.5, units = "in")

# SVM
plot(svm.fit)
svm.pred <- predict(svm.fit, valid)
svm.out <- multiClass(svm.pred,valid$actor)

plotROC(svm.out, "Radial SVM") + ggsave(filename = "Plots/svm.png",
                                        width = 11, height = 8.5, units = "in")

# C5.0
plot(c5.fit)

c5.pred <- predict(c5.fit, valid)
c5.out <- multiClass(c5.pred,valid$actor)

plotROC(c5.out, "C5.0 Rules") + ggsave(filename = "Plots/c5.png",
                                       width = 11, height = 8.5, units = "in")

# Random Forest
plot(rf.fit)
rf.pred <- predict(rf.fit, valid)
rf.out <- multiClass(rf.pred,valid$actor)

plotROC(rf.out, "Random Forest") + ggsave(filename = "Plots/rf.png",
                                          width = 11, height = 8.5, units = "in")

# XGB
plot(xgb.fit)

xgb.pred <- predict(xgb.fit, valid)
# predict(xgb.fit, valid, type="prob")
xgb.out <- multiClass(xgb.pred,valid$actor)

plotROC(xgb.out, "XGBoost") + ggsave(filename = "Plots/xgb.png",
                                     width = 11, height = 8.5, units = "in")

# NN
plot(nn.fit)

nn.pred <- predict(nn.fit, valid)
# predict(xgb.fit, valid, type="prob")
nn.out <- multiClass(nn.pred,valid$actor)

plotROC(nn.out, "Neural Net") + ggsave(filename = "Plots/nn.png",
                                    width = 11, height = 8.5, units = "in")

## SMOTE'D ##

# NB
plot(nb.fit2)
nb.pred <- predict(nb.fit2, valid)
nb.out <- multiClass(nb.pred,valid$actor)

plotROC(nb.out, "(SMOTE) Naive Bayes") + ggsave(filename = "Plots/smote_nb.png",
                                                width = 11, height = 8.5, units = "in")

# SVM
plot(svm.fit2)
svm.pred <- predict(svm.fit2, valid)
svm.out <- multiClass(svm.pred,valid$actor)

plotROC(svm.out, "(SMOTE) Radial SVM") + ggsave(filename = "Plots/smote_svm.png",
                                                width = 11, height = 8.5, units = "in")

# C5.0
plot(c5.fit2)

c5.pred <- predict(c5.fit2, valid)
c5.out <- multiClass(c5.pred,valid$actor)

plotROC(c5.out, "(SMOTE) C5.0 Rules") + ggsave(filename = "Plots/smote_c5.png",
                                               width = 11, height = 8.5, units = "in")

# Random Forest
plot(rf.fit2)
rf.pred <- predict(rf.fit2, valid)
rf.out <- multiClass(rf.pred,valid$actor)

plotROC(rf.out, "(SMOTE) Random Forest") + ggsave(filename = "Plots/smote_rf.png",
                                                  width = 11, height = 8.5, units = "in")

# XGB
plot(xgb.fit2)

xgb.pred <- predict(xgb.fit2, valid)
# predict(xgb.fit, valid, type="prob")
xgb.out <- multiClass(xgb.pred,valid$actor)

plotROC(xgb.out, "(SMOTE) XGBoost") + ggsave(filename = "Plots/smote_xgb.png",
                                             width = 11, height = 8.5, units = "in")

# NN
plot(nn.fit2)

nn.pred <- predict(nn.fit2, valid)
# predict(xgb.fit, valid, type="prob")
nn.out <- multiClass(nn.pred,valid$actor)

plotROC(nn.out, "(SMOTE) Neural Net") + ggsave(filename = "Plots/smote_nn.png",
                                              width = 11, height = 8.5, units = "in")

## Oversampling minority Classes ##

# NB
plot(nb.fit3)
nb.pred <- predict(nb.fit3, valid)
nb.out <- multiClass(nb.pred,valid$actor)

plotROC(svm.out, "(Oversampled) Naive Bayes") + ggsave(filename = "Plots/os_nb.png",
                                                      width = 11, height = 8.5, units = "in")

# SVM
plot(svm.fit3)
svm.pred <- predict(svm.fit3, valid)
svm.out <- multiClass(svm.pred,valid$actor)

plotROC(svm.out, "(Oversampled) Radial SVM") + ggsave(filename = "Plots/os_svm.png",
                                                     width = 11, height = 8.5, units = "in")

# C5.0
plot(c5.fit3)

c5.pred <- predict(c5.fit3, valid)
c5.out <- multiClass(c5.pred,valid$actor)

plotROC(c5.out, "(Oversampled) C5.0 Rules")+ ggsave(filename = "Plots/os_c5.png",
                                                    width = 11, height = 8.5, units = "in")

# Random Forest
plot(rf.fit3)
rf.pred <- predict(rf.fit3, valid)
rf.out <- multiClass(rf.pred,valid$actor)

plotROC(rf.out, "(Oversampled) Random Forest") + ggsave(filename = "Plots/os_rf.png",
                                                       width = 11, height = 8.5, units = "in")

# XGB
plot(xgb.fit3)

xgb.pred <- predict(xgb.fit3, valid)
# predict(xgb.fit, valid, type="prob")
xgb.out <- multiClass(xgb.pred,valid$actor)

plotROC(xgb.out, "(Oversampled) XGBoost")+ ggsave(filename = "Plots/os_xgb.png",
                                                  width = 11, height = 8.5, units = "in")

# NN
plot(nn.fit3) 

nn.pred <- predict(nn.fit3, valid)
# predict(xgb.fit, valid, type="prob")
nn.out <- multiClass(nn.pred,valid$actor)

plotROC(nn.out, "(Oversampled) Neural Net") + ggsave(filename = "Plots/os_nn.png",
                                                     width = 11, height = 8.5, units = "in")

#### Model Candidates ####
library(caret)
# Radial SVM, XGB and Random Forest on the raw data are the candidates
set.seed(007)
final.svm <- train(actor~., train,
                 method = "svmRadial",
                 verbose = T,
                 tuneGrid = svm.fit$bestTune,
                 preProc = c("center","scale"))
final.pred <- predict(final.svm, valid)
final.out <- multiClass(final.pred, valid$actor)

plotROC(final.out, "Radial SVM (Full Training Set)") +
  ggsave(filename = "Plots/FINAL_svm.png",
         width = 11, height = 8.5, units = "in")

set.seed(007)
final.rf<- train(actor~., train,
                   method = "parRF",
                   verbose = T,
                   tuneGrid = rf.fit$bestTune)
final.pred <- predict(final.rf, valid)
final.out <- multiClass(final.pred, valid$actor)

plotROC(final.out, "Random Forest (Full Training Set)") +
  ggsave(filename = "Plots/FINAL_rf.png",
         width = 11, height = 8.5, units = "in")

set.seed(007)
final.xgb <- train(actor~., train,
                   method = "xgbTree",
                   verbose = T,
                   tuneGrid = xgb.fit$bestTune)
final.pred <- predict(final.xgb, valid)
final.out <- multiClass(final.pred, valid$actor)

plotROC(final.out, "XG Boost (Full Training Set)") +
  ggsave(filename = "Plots/FINAL_xgb.png",
          width = 11, height = 8.5, units = "in")

#### Train Final Model ####
# Looks like XG Boost Won, woot!

set.seed(007)
final <- train(actor~., bond.actor,
                   method = "svmRadial",
                   verbose = T,
               tuneGrid = svm.fit$bestTune,
               preProc = c("center","scale"))
final.pred <- predict(final, bond.actor)
final.out <- multiClass(final.pred, bond.actor$actor)

plotROC(final.out, "XG Boost (All Data)") # + ggsave(filename = "Plots/FINAL.png",
                                                   width = 11, height = 8.5, units = "in")


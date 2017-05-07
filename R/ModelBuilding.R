# # Proportion of Actors
# ggplot(as.data.frame(table(bond.actor$actor)*100/nrow(bond.actor)),
#        aes(x= Var1, y = Freq, fill = Var1)) +
#   geom_bar(stat = "identity") +
#   scale_fill_brewer(type = "qual", palette = "Blues",
#                     breaks = c("Sean Connery",
#                                "George Lazenby",
#                                "Roger Moore",
#                                "Timothy Dalton",
#                                "Pierce Brosnan",
#                                "Daniel Craig"),
#                     labels = c("Connery",
#                                "Lazenby",
#                                "Moore",
#                                "Dalton",
#                                "Brosnan",
#                                "Craig")) + 
#   theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
#   guides(fill=F) + 
#   ggtitle("Distribution (%) of Tracks by Actor")
# 
# # Proportion of Films
# plot(table(bond.film$film)*100/nrow(bond.film))
# 
# ggplot(as.data.frame(table(bond.film$film)*100/nrow(bond.film)),
#        aes(x= Var1, y = Freq, fill = Var1)) +
#   geom_bar(stat = "identity") +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
#   guides(fill=F) + 
#   ggtitle("Distribution (%) of Tracks by Film")


#### Model Fitting ####
# For MultiCore
# library(doMC)
# registerDoMC(cores = 1)

library(plyr)
library(dplyr)
library(caret)

# Create an 80/20 Split of training/testing and validation data
set.seed(007)
partitions <- createDataPartition(bond.actor$actor, times = 10, p =.8, list = F)

# Create training and validation sets, changing "actor" to a valid name
train <- bond.actor[partitions[,7],] %>%
  mutate(actor = factor(make.names(actor),levels = c("Sean.Connery",
                                                     "George.Lazenby",
                                                     "Roger.Moore",
                                                     "Timothy.Dalton",
                                                     "Pierce.Brosnan",
                                                     "Daniel.Craig")))
valid <- bond.actor[-partitions[,7],] %>% 
  mutate(actor = factor(make.names(actor),levels = c("Sean.Connery",
                                                     "George.Lazenby",
                                                     "Roger.Moore",
                                                     "Timothy.Dalton",
                                                     "Pierce.Brosnan",
                                                     "Daniel.Craig")))


fitControl <- trainControl(method = "repeatedcv",
                           number = 5,
                           repeats = 10,
                           classProbs = T,
                           summaryFunction = multiClassSummary,
                           allowParallel = T)


#### Bayes with density distributions ####
library(klaR)
library(Metrics)

nb.grid <- expand.grid(.usekernel=T, .adjust=seq(0,1,.1), .fL=seq(0,1,.1))

set.seed(007)
nb.fit1 <- train(actor~., train,
                 method = "nb",
                 trControl = fitControl,
                 tuneGrid = nb.grid,
                 metric = "AUC")

# Build the Naive Bayes models manually (caret throws an error)

# Use 5-fold CV
source("R/ROC Tests.R")
set.seed(007)
folds <- createFolds(train$actor, k=5)

all_auc_T <- NULL
all_preds_T <- NULL
for (k in folds){
  nb <- NaiveBayes(actor~.,train[-k,],usekernel =T)
  nb.pred <- predict(nb, train[k,])
  temp <- multiClass(nb.pred$class,train$actor[k])
  all_auc_T <- rbind(all_auc_T,temp$auc)
  all_preds_T <- rbind(all_preds_T,temp$out)
}

# Average 5-Fold CV'd AUC as a baseline
colMeans(all_auc_T)

# Without the Kernel
all_auc_F <- NULL
all_preds_F <- NULL
for (k in folds){
  nb <- NaiveBayes(actor~.,train[-k,],usekernel = F)
  nb.pred <- predict(nb, train[k,])
  temp <- multiClass(nb.pred$class,train$actor[k])
  all_auc_F <- rbind(all_auc_F,temp$auc)
  all_preds_F <- rbind(all_preds_F,temp$out)
}

# Average 5-Fold CV'd AUC as a baseline
colMeans(all_auc_F)



#### SVM ####
svm.grid = expand.grid(.sigma = .06,.C = c(seq(0,1,.1)))

set.seed(007)
svm.fit <- train(actor~., train,
                 method = "svmRadial",
                 trControl = fitControl,
                 verbose = T,
                 #tuneGrid = svm.grid,
                 preProc = c("center","scale"),
                 metric = "AUC")


#### C5.0 Trees ####

c50Grid <- expand.grid(.trials = c(1:100),
                       .model = c("rules","tree"),
                       .winnow = c(T,F))

set.seed(007)
c5.fit <- caret::train(actor~.,
                       train,
                       method = "C5.0",
                       trControl = fitControl,
                       verbose = T,
                       # preProc = c("center","scale"),
                       tuneGrid = c50Grid,
                       metric = "AUC")

#### Random Forest ####

rf.grid <- expand.grid(.mtry=seq(1,13))

set.seed(007)
rf.fit <- train(actor~., train,
                method = "parRF",
                trControl = fitControl,
                verbose = T,
                tuneGrid = rf.grid,
                metric = "AUC")

#### XGB Tree ####

set.seed(007)
xgb.fit <- train(actor~., train,
                 method = "xgbTree",
                 trControl = fitControl,
                 verbose = T,
                 tuneLength = 5,
                 metric = "AUC")

#### ANN ####


nn.grid <- expand.grid(.layer1 = c(1:13),
                       .layer2 = c(0:13),
                       .layer3 = c(0:5),
                       .hidden_dropout = c(0.2),
                       .visible_dropout=0)
set.seed(007)
nn.fit <- train(actor~., train,
                method = "dnn",
                trControl = fitControl,
                tuneGrid = nn.grid,
                metric = "AUC")



#### Try everything, SMOTE'd, and with Accuracy ####

fitControl <- trainControl(method = "repeatedcv",
                           number = 5,
                           repeats = 10,
                           sampling = "smote",
                           classProbs = T,
                           #summaryFunction = multiClassSummary,
                           allowParallel = T)
#### NB ####

# Still fails
set.seed(007)
nb.fit2 <- train(actor~., train,
                 method = "nb",
                 trControl = fitControl,
                 tuneGrid = nb.grid,
                 metric = "Accuracy")

#### SVM ####
set.seed(007)
svm.fit2 <- train(actor~., train,
                 method = "svmRadial",
                 trControl = fitControl,
                 verbose = T,
                 tuneGrid = svm.grid,
                 preProc = c("center","scale"),
                 metric = "Accuracy")


#### C5.0 Trees ####

set.seed(007)
c5.fit2 <- caret::train(actor~.,
                       train,
                       method = "C5.0",
                       trControl = fitControl,
                       verbose = T,
                       # preProc = c("center","scale"),
                       tuneGrid = c50Grid,
                       metric = "Accuracy")

#### Random Forest ####
set.seed(007)
rf.fit2 <- train(actor~., train,
                method = "parRF",
                trControl = fitControl,
                verbose = T,
                tuneGrid = rf.grid,
                metric = "Accuracy")

#### XGB Tree ####

set.seed(007)
xgb.fit2 <- train(actor~., train,
                 method = "xgbTree",
                 trControl = fitControl,
                 verbose = T,
                 tuneLength = 5,
                 metric = "Accuracy")

#### ANN ####

set.seed(007)
nn.fit2 <- train(actor~., train,
                method = "dnn",
                trControl = fitControl,
                tuneGrid = nn.grid,
                metric = "Accuracy")

#### Try everything, upsampled, and with Accuracy ####

fitControl$sampling = "up"

#### NB ####

set.seed(007)
nb.fit3 <- train(actor~., train,
                       method = "nb",
                       trControl = fitControl,
                       tuneGrid = nb.grid,
                       metric = "Accuracy")

#### SVM ####
set.seed(007)
svm.fit3 <- train(actor~., train,
                  method = "svmRadial",
                  trControl = fitControl,
                  verbose = T,
                  tuneGrid = svm.grid,
                  preProc = c("center","scale"),
                  metric = "Accuracy")


#### C5.0 Trees ####

set.seed(007)
c5.fit3 <- caret::train(actor~.,
                        train,
                        method = "C5.0",
                        trControl = fitControl,
                        verbose = T,
                        # preProc = c("center","scale"),
                        tuneGrid = c50Grid,
                        metric = "Accuracy")

#### Random Forest ####
set.seed(007)
rf.fit3 <- train(actor~., train,
                 method = "parRF",
                 trControl = fitControl,
                 verbose = T,
                 tuneGrid = rf.grid,
                 metric = "Accuracy")

#### XGB Tree ####

set.seed(007)
xgb.fit3 <- train(actor~., train,
                  method = "xgbTree",
                  trControl = fitControl,
                  verbose = T,
                  tuneLength = 5,
                  metric = "Accuracy")

#### ANN ####

set.seed(007)
nn.fit3 <- train(actor~., train,
                 method = "dnn",
                 trControl = fitControl,
                 tuneGrid = nn.grid,
                 metric = "Accuracy")
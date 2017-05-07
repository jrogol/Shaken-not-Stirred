# Proportion of Actors
ggplot(as.data.frame(table(bond.actor$actor)*100/nrow(bond.actor)),
       aes(x= Var1, y = Freq, fill = Var1)) +
  geom_bar(stat = "identity") +
  scale_fill_brewer(type = "qual", palette = "Blues",
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
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  guides(fill=F) + 
  ggtitle("Distribution (%) of Tracks by Actor")

# Proportion of Films
plot(table(bond.film$film)*100/nrow(bond.film))

ggplot(as.data.frame(table(bond.film$film)*100/nrow(bond.film)),
       aes(x= Var1, y = Freq, fill = Var1)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  guides(fill=F) + 
  ggtitle("Distribution (%) of Tracks by Film")


#### Naive Bayes ####
library(e1071)

set.seed(41684)
# Create 50/50 Split
trainTest <- ifelse(runif(nrow(bond.actor))<0.80,1,0)
nb_model <- naiveBayes(actor~.-time_signature, bond.actor, subset = trainTest == 1)

nb_test_predict <- predict(nb_model,bond.actor %>% 
                             dplyr::select(-actor) %>%
                             slice(which(trainTest == 0)))
nb_test_gt <- bond.actor %>% 
  slice(which(trainTest == 0)) %>% .$actor

library(caret)
confusionMatrix(nb_test_predict,nb_test_gt)

#confusion matrix
table(pred=nb_test_predict,true= bond.actor %>%
        slice(which(trainTest == 0)) %>%
        .$actor)
# Fractions of predictions
mean(nb_test_predict==bond.actor %>%
       slice(which(trainTest == 0)) %>%
       .$actor)

# Cross-Validate it!
set.seed(41684)
trainTestCV <- sample(rep_len(1:10,nrow(bond.actor)))

CV.out <-c()
for (i in 1:10){
  nb_model <- naiveBayes(actor~., bond.actor, subset = trainTestCV != i)
  nb_test_predict <- predict(nb_model,bond.actor %>% 
                               select(-actor) %>%
                               slice(which(trainTestCV == i)))
  table(pred=nb_test_predict,true= bond.actor %>%
          slice(which(trainTestCV == i)) %>%
          .$actor)
  # Fractions of predictions
 CV.out <- c(CV.out,mean(nb_test_predict==bond.actor %>%
         slice(which(trainTestCV == i)) %>%
         .$actor))
}


library(pROC)

nb_test_predict <- predict(nb_model,bond.actor %>% 
                             select(-actor) %>%
                             slice(which(trainTest == 0)))
XX <- multiclass.roc(response = bond.actor %>%
                 slice(which(trainTest == 0)) %>%
                 .$actor, factor(nb_test_predict, levels = c("Sean Connery",
                                                             "George Lazenby",
                                                             "Roger Moore",
                                                             "Pierce Brosnan",
                                                             "Daniel Craig"),
                                 ordered = T))

# Function, adapted from Introduction to Statistical Learning, which will create
# ROC curves from a vector of predicted values (pred) and the ground truth (truth)
roccurve <- function(pred, truth, ...){
  require(ROCR)
  predob <- prediction(pred, truth)
  perf <- performance(predob, "tpr", "fpr")
  auc = performance(predob, "auc")@y.values[[1]]
  
  # plot
  plot(perf, main = paste("ROC (AUC=", round(auc,2), ")", sep=""), ...)
  abline(0, 1, lty="dashed")
}



#### Model Fitting ####
# For MultiCore
library(doMC)
registerDoMC(cores = 3)
library(caret)
library(plyr)
library(dplyr)
# Create an 80/20 Split of training/testing and validation data
set.seed(007)
partitions <- createDataPartition(bond.actor$actor, times = 10, p =.8, list = F)

# Create training and validation sets, changing "actor" to a valid name
train <- bond.actor[partitions[,7],] %>% mutate(actor = make.names(actor))
valid <- bond.actor[-partitions[,7],] %>% mutate(actor = make.names(actor))


fitControl <- trainControl(method = "repeatedcv",
                           number = 5,
                           repeats = 10,
                           #sampling = "up",
                           classProbs = T,
                           summaryFunction = multiClassSummary,
                           allowParallel = T)


#### Bayes with density distributions ####
library(klaR)
library(Metrics)

nb.grid <- expand.grid(.usekernel=c(T,F),.adjust=F,.fL=c(0,.5,1))


# Build the Naive Bayes models
set.seed(007)
nb.models <- train(actor~., train,
                   method = "nb",
                 trControl = fitControl,
                 verbose = T,
                 tuneGrid = nb.grid,
                 metric = "ROC")


#### SVM ####
svm.grid = expand.grid(.sigma = seq(0,.2, .015),.C = c(seq(0,1,.1),seq(1.5,10,.5)))

set.seed(007)
svm.fit <- train(actor~., train,
                 method = "svmRadial",
                 trControl = fitControl,
                 verbose = T,
                 tune = svm.grid,
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
                       preproc = c("center","scale"),
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

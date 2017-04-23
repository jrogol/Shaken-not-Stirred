library(e1071)

# Proportion of Actors
plot(table(actor$actor)*100/nrow(actor))

# Proportion of Films
plot(table(film$film)*100/nrow(film))

#### Naive Bayes ####
set.seed(41684)
trainTest <- ifelse(runif(nrow(actor))<0.80,1,0)
nb_model <- naiveBayes(actor~., bond.actor, subset = trainTest == 1)

nb_test_predict <- predict(nb_model,bond.actor %>% 
                             select(-actor) %>%
                             slice(which(trainTest == 0)))



#confusion matrix
table(pred=nb_test_predict,true= bond.actor %>%
        slice(which(trainTest == 0)) %>%
        .$actor)
# Fractions of predictions
mean(nb_test_predict==test$actor)

# Cross-Validate it!
set.seed(41684)
trainTestCV <- sample(rep_len(1:10,nrow(bond.actor)))


for (i in 1:10){
  nb_model <- naiveBayes(actor~., bond.actor, subset = trainTestCV != i)
  nb_test_predict <- predict(nb_model,bond.actor %>% 
                               select(-actor) %>%
                               slice(which(trainTestCV == i)))
  table(pred=nb_test_predict,true= bond.actor %>%
          slice(which(trainTestCV == i)) %>%
          .$actor)
  # Fractions of predictions
  mean(nb_test_predict==bond.actor %>%
         slice(which(trainTestCV == i)) %>%
         .$actor)
}


library(pROC)
XX <- multiclass.roc(response = bond.actor %>%
                 slice(which(trainTest == 0)) %>%
                 .$actor, factor(nb_test_predict, levels = c("Sean Connery",
                                                             "George Lazenby",
                                                             "Roger Moore",
                                                             "Pierce Brosnan",
                                                             "Daniel Craig"),
                                 ordered = T))

#### SVM ####
svm_test <- svm(as.factor(actor)~., bond.actor %>%
      mutate(mode = as.factor(mode)), kernel = 'radial',
      subset = trainTest == 1)

svm_preds <- predict(svm_test, subset(bond.actor %>% mutate(mode = as.factor(mode)), trainTest == 0))

table(pred = svm_preds, true = subset(bond.actor$actor, trainTest == 0))


svm.fit <- train(actor~., bond.actor, method = "svmRadial",
                 trControl = fitControl, verbose = T)

#### C5.0 Trees ####
library(caret)

fitControl <- trainControl(method = "repeatedcv",
                           number = 10,
                           repeats = 10, sampling = "smote")

c5.fit <- train(actor~., bond.actor, method = "C5.0",
                trControl = fitControl, verbose = T)


#### Random Forest ####

rf.fit <- train(actor~., bond.actor, method = "rf",
                trControl = fitControl)

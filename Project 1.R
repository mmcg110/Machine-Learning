library(caret)
dataTrain <- read.csv(url("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"), na.strings = "NA")
dataTest <- read.csv(url("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"), na.strings = "NA")

#Remove time variables from training predictors
exclude <- seq(1:7)
dataTrain <- dataTrain[,-exclude]
dataTest <- dataTest[,-exclude]

#Remove training variables with more than 80% NA values
NAthresh <- 0.2
NAcols <- apply(dataTrain, 2, function(x) sum(is.na(x))/length(x)>NAthresh)

dataTrain <- dataTrain[,!NAcols]
dataTest <- dataTest[,!NAcols]

#Remove training columns with zero zero variance
nzv <- nearZeroVar(dataTrain)
dataTrain <- dataTrain[,-nzv]
dataTest <- dataTest[,-nzv]

#Check for high correlation
trainCorr <- cor(dataTrain[,-dim(dataTrain)[2]])
highCorr <- findCorrelation(trainCorr, 0.9)
dataTrain <- dataTrain[,-highCorr]
dataTest <- dataTest[,-highCorr]


#Train model using rf and GBM, set training parameters
inTrain <- createDataPartition(dataTrain$classe, p=0.75, list = FALSE)
training <- dataTrain[inTrain,]
testing <- dataTrain[-inTrain,]

trainCtrl <- trainControl(method = "repeatedcv",
                          number = 5,
                          repeats = 3,
                          verboseIter = TRUE)
rf_mod <- train(classe ~., data = training, method = "rf", trControl = trainCtrl)

grid <- expand.grid(n.trees=150,
                    shrinkage=0.1,
                    n.minobsinnode = 10,
                    interaction.depth=7)
gbm_mod <- train(classe ~., data = training, method = "gbm", trControl = trainCtrl, tuneGrid = grid)


# Predict on test set and estimate out-of-sample accuracy

predRF <- predict(rf_mod$finalModel, testing)
predGBM <- predict(gbm_mod, testing)

confusionMatrix(predRF, testing$classe)
confusionMatrix(predGBM, testing$classe)

#Predict on testing set using RF model

predFinal <- predict(rf_mod, dataTest)


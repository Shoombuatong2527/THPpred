#######set directory
setwd('D:\\Peptide prediction\\Tumor homing peptides\\Data set')
#######Load package
library(randomForest)
library(protr)
library(seqinr)
library(C50)
library(RWeka)
library(Interpol)
library(caret)
library(AUC)
library(ROCR)
####################Read data
A <- read.fasta('small.fasta', seqtype="AA", as.string = TRUE)
D = read.csv("label small.csv", header = TRUE) 
pcp = read.csv("PCP.csv", header = TRUE) 
m = length(A)
PCP  <- matrix(nrow = m, ncol = 531)

################PCP representation
for(i in 1:m){ 
x = A[[i]][1]
b = AAdescriptor(x, 531,1)
PCP[i,] = Interpol(b, 531,"linear")
}

internal = data.frame(PCP,Class = D)

#######Ranking PCPs using MDGI
ind= c(2,3,5,7,9,11,13,15,17,20)
n = ncol(internal)-1
gini = matrix(nrow = n, ncol = 10)
meangini = matrix(nrow = 531, ncol = 1)

for (i in 1:10){
RF<-randomForest(Class~.,data=internal,ntree=100,mtry=ind[i],importance=TRUE)
gini[,i] = RF$ importance[,4]
}

for (i in 1:531){
meangini[i,] = mean(gini[i,])
}

rankpcp = internal[,-ncol(internal)]
rankpcp2 = t(rankpcp)
mdgi = data.frame(rankpcp2,meangini)
ranked_pcp = mdgi[order(mdgi$meangini, decreasing=T),]

data_ranked_pcp = data.frame(t(ranked_pcp[,-ncol(ranked_pcp)]))
###########################################################################
customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
customRF$parameters <- data.frame(parameter = c("mtry", "ntree"), class = rep("numeric", 2), label = c("mtry", "ntree"))
customRF$grid <- function(x, y, len = NULL, search = "grid") {}
customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
  randomForest(x, y, mtry = param$mtry, ntree=param$ntree, ...)
}
customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata)
customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata, type = "prob")
customRF$sort <- function(x) x[order(x[,1]),]
customRF$levels <- function(x) x$classes

############ m is a number of informative PCPs used to construct a model, such as m = 5, 10, 15, ...
internal =data.frame(data_ranked_pcp[,1:5],Class = D)
tunegrid <- expand.grid(.mtry=c(1:5), .ntree=seq(100,500,100))
RFmodel <- train(Class~., data=internal , method=customRF, metric=c("Accuracy"), tuneGrid=tunegrid, trControl=trainControl(method = "cv", number=5))
Resultcv = RFmodel$ finalModel$ confusion [,1:2] 
pred=prediction(RFmodel$ finalModel$ votes[,2],internal[,ncol(internal)])
perf_AUC=performance(pred,"auc") #Calculate the AUC value
AUC = perf_AUC@y.values[[1]]

data = Resultcv
	ACCtr = ((data[1]+data[4])/(data[1]+data[2]+data[3]+data[4]))*100
	SENStr =  (data[1]/(data[1]+data[2]))*100
	SPECtr = (data[4])/(data[3]+data[4])*100
	MCC1      = (data[1]*data[4]) - (data[2]*data[3])
	MCC2      =  (data[4]+data[2])*(data[4]+data[3])
	MCC3      =  (data[1]+data[2])*(data[1]+data[3])
	MCC4	=  sqrt(MCC2)*sqrt(MCC3)
	MCCtr  = MCC1/MCC4

data.frame (ACCtr,SENStr,SPECtr,MCCtr,AUC)

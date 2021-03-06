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

rankpcp = data.frame(pcp,meangini)
rankpcp2 = rankpcp[order(rankpcp$meangini, decreasing=T),]

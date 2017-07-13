## Adam Hendel
## ANN to predict NHL playoff outcomes based on regular season stats

library(neuralnet)


setwd("C:/Users/AdamHendel/OneDrive/Analytics/NHL/Raw")

# # # Ste 1: Normalize the Raw Data # # #
nhlData <- read.csv("NHL Stat DB_2008_2017.csv",
                    header = T)

# remove irrelevant columns
nhlData <- subset(nhlData, select = -c(GP))

# scale all the data, except playoff rank
years <- unique(nhlData$Year)
for (i in 1:length(years)){
  d <- nhlData[nhlData$Year == years[i],]
  d[,7:length(d)] <- scale(d[,7:length(d)], center = T, scale = T)
  nhlData[nhlData[,"Year"] == years[i],] <- d
}

nhlCurr <- nhlData[nhlData$Year == 2017,]
nhlCurr <- nhlCurr[nhlCurr$CY.Season.Rank < 18,]
nhlCurr <- nhlCurr[nhlCurr$Team != "Tampa Bay Lightning",]
# remove teams that didnt make playoffs, and not current year
nhlData <- nhlData[nhlData$Year < 2017,]
nhlData <- nhlData[nhlData$CY.Playoff.Rank < 17,]



#replace NA values with zeros (z score of zero)
nhlData[is.na(nhlData)] <- 0
nhlCurr[is.na(nhlCurr)] <- 0
#set outliers >3, equal to 3
# should we do this?
#nhlData[sum(nhlData[,7:67] > 3),7:67] <- 3

# # # # # # # # # # # # # # # # # # # # # # # 
# # # Step 2: Apply PCA # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # 
# copy over the data from Step 1
d <- nhlData
d <- nhlCurr
#categorize 
grit <- d[,c("W", "ROW", "OT", "FOW.", "OZFO.", "DZFO.", "NZFO.")]

offense <- d[,c("GF","GF.GP", "PP.", "Shots.GP", "TOI", "GF.",
                "SF", "SF.", "Sh.", "GF60", "SF60")]
# GF. and SF. are goal for and shot percentage

defense <- d[,c("GA.GP", "PK.", "GA", "GA60", "SA", "SA60")]
defense$PK. <- defense$PK.* -1
#flip sign on pk, so all signs go in same direction
# these are defensive, low is good in all categories here

goalie <- d[,"Sv."]

other <- d[,c("L", "P", "FF", "FA", "FF60", "FA60", "FF.", "CF",
              "CA", "CF60", "CA60", "CF.")]
other$L <- other$L * -1
# high is good in these categories, so flip losses

history <- d[,c("PY.Playoff.RNK",	"X2PY.Playoff.RNK",	"X3PY.Playoff.RNK",
                "X4PYPlayoff.RNK")]#,	"PY.PlayoffGP",	"PY.PlayoffW",	
                # "PY.PlayoffL",	"PY.PlayoffGF",	"PY.PlayoffGA",	
                # "PY.PlayoffGF.GP",	"PY.PlayoffGA.GP",	"PY.PlayoffPP.",
                # "PY.PlayoffPK.",	"PY.PlayoffShots.GP",	"PY.PlayoffSA.GP",
                # "PY.PlayoffFOW.")]
history$PY.Playoff.RNK <- history$PY.Playoff.RNK*-1
history$X2PY.Playoff.RNK <- history$X2PY.Playoff.RNK*-1
history$X3PY.Playoff.RNK <- history$X3PY.Playoff.RNK*-1
history$X4PYPlayoff.RNK <- history$X4PYPlayoff.RNK*-1
#history$PY.PlayoffL <- history$PY.PlayoffL*-1
#history$PY.PlayoffGA <- history$PY.PlayoffGA*-1
#history$PY.PlayoffGA.GP <- history$PY.PlayoffGA.GP*-1
#history$PY.PlayoffSA.GP <- history$PY.PlayoffSA.GP*-1

luck <- d[,"PDO"]

# prcomp() gives us variance values for principal components
# grit analysis
PCA.grit <- prcomp(grit, scale = T)
summary(PCA.grit)
PCA.grit <- PCA.grit$x[,1:4]
colnames(PCA.grit) <- c("Grit1", "Grit2", "Grit3", "Grit4")
#PCA.grit <- PCA.grit$x[,1]

# offense analysis
PCA.offense2 <- prcomp(offense, scale = T)
summary(PCA.offense2)
PCA.offense <- PCA.offense2$x[,1:3]
colnames(PCA.offense) <- c("Off1", "Off2", "off3")
#PCA.offsense <- PCA.offense2$x[,1]

#defense analysis
PCA.defense <- prcomp(defense, scale = T)
summary(PCA.defense)
PCA.defense <- PCA.defense$x[,1:3]
colnames(PCA.defense) <- c("def1", "def2", "def3")
#PCA.defense <- PCA.defense$x[,1]

#other
PCA.other <- prcomp(other, scale = T)
summary(PCA.other)
PCA.other <- PCA.other$x[,1:3]
colnames(PCA.other) <- c("oth1", "oth2", "oth3")
#PCA.other <- PCA.other$x[,1]


#history
PCA.history <- prcomp(history, scale = T)
summary(PCA.history)
PCA.history <- PCA.history$x[,1:3]
colnames(PCA.history) <- c("hist1", "hist2", "hist3")
#PCA.history <- PCA.history$x[,1]

nhlPCA <- cbind(d[,1:6], PCA.grit, PCA.offense, PCA.defense, PCA.other, PCA.history, goalie, luck)

PCA.tng <- nhlPCA
PCA.curr <- nhlPCA
# # # # # # # # # # # # # # # # # # # # # #
# # # Separate Training and Test Sets # # #
# # # # # # # # # # # # # # # # # # # # # #
allData <- nhlPCA
rnk.mean <- mean(1:16)
rnk.sd <- sd(1:16)

#separate training and test data
testDat <- allData[allData$Year == 2016,]
# copy the actualy ranks, and team names
actualRnk <- testDat$CY.Playoff.Rank
actualRaw <- (actualRnk*rnk.sd) + rnk.mean
testNames <- testDat$Team
# remove un needed columns
testDat <- subset(testDat,
                  select = -c(CY.Season.Rank, Year, Team, YrTm, Season))

# now build the training set
trainingDat <- allData[allData$Year < 2016,]
# remove the unncessesary columns
trainingDat <- subset(trainingDat,
                      select = -c(CY.Season.Rank, Year, Team, YrTm, Season))

# # # # # # # # # # # # # # # # # # # # # # # 
# # # Step 3: Train the Neural Network # # #
# # # # # # # # # # # # # # # # # # # # # # # 

# set the function, inputs and outputs
f <- as.formula(CY.Playoff.Rank ~ Grit1 + Grit2 + Grit3 + Off1 + Off2 + def1 + def2 + oth1 +
                  oth2 + hist1 + hist2 + goalie + luck)

# model 2
# f <- as.formula(CY.Playoff.Rank ~ Grit1 + Off1 + def1 + oth1 + goalie + luck)
# trainingDat <- subset(trainingDat, select = -c(Grit2, Grit3, Off2, def2, oth2, hist1, hist2))
# testDat <- subset(testDat, select = -c(Grit2, Grit3, Off2, def2, oth2, hist1, hist2))
# train the network
model <- neuralnet(f,
                  data = trainingDat,
                  hidden = c(14,14,3),
                  act.fct = "logistic",
                  linear.output = T,
                  stepmax = 1e6)

# compare prediction with actual data
results <- compute(model, testDat[,2:14])
#compute model 2
#results <- compute(model, testDat[,2:7])
prediction <- results$net.result
predRes <- data.frame(team = testNames,
                      prediction = prediction,
                      actual = actualRaw)
predRes$prediction <- (predRes$prediction*rnk.sd) + rnk.mean
# plot(predRes$actualRnk, predRes$prediction)
predRes
# # # Step 4: Naive Bayes # # # 
library(e1071)
# for actual prediction
nbTng <- PCA.tng
nbTng <- nhlData
nbTng <- nbTng[,5:ncol(nbTng)]

nbTest <- PCA.curr
nbTest <- nhlCurr
#nbTest <- nbTest[nbTest$CY.Season.Rank < 18,]
#nbTest <- nbTest[nbTest$Team != "Tampa Bay Lightning",]
teamNames <- nbTest$Team
nbTest <- nbTest[,5:ncol(nbTest)]

# need to figure out ordering in NB factors
nbTng$CY.Playoff.Rank <- factor(nbTng$CY.Playoff.Rank, 
                                ordered = T,
                                levels = 1:16)

nbTest$CY.Playoff.Rank <- NULL

#build model
nbmod <- naiveBayes(CY.Playoff.Rank ~., 
                    data = nbTng,
                    laplace = 1)

pred <- predict(nbmod, nbTest)

results <- data.frame(team = teamNames,
                      rank = pred)
results
write.csv(results, "nbV4_2017.csv", row.names = F)






plot(as.numeric(nb.results$nb), as.numeric(nb.results$actual))
write.csv(nb.results, "NaiveBay_NHL2016_Results.csv", row.names = F)


# # # Step 5: KNN # # # 
library(class)
knTng <- trainingDat
knTst <- testDat
# unscale the categories (predictions) for knn
knTng$CY.Playoff.Rank <- (knTng$CY.Playoff.Rank*rnk.sd) + rnk.mean
knTst$CY.Playoff.Rank <- (knTst$CY.Playoff.Rank*rnk.sd) + rnk.mean
actualRnk <- (actualRnk*rnk.sd) + rnk.mean

# set a vector for the categories in the training data
cl <- knTng$CY.Playoff.Rank

# do knn
predicted <- knn(train = knTng[,2:14], 
              test = knTst[,2:14], 
              cl = cl, 
              k = 6)
results <- data.frame(team = testNames,
                      predicted = predicted,
                      actual = actualRnk
                      )
write.csv(results, "KNN_NHL2016 Results.csv", row.names = F)
# # optimize K value
# total number of test points
tot.test <- length(knTst$CY.Playoff.Rank)
sum(predicted != actualRnk) / tot.test

#1 Try a range of k values for the model (max of all the test data points!)
n <- tot.test
# set up an array to store the error rate for each value of k
misclassification.rate = matrix(nrow = n, ncol =2)

# use a for loop to iterate through a range 1 to n of k values
# find the one that has lowest error (rank - predicted)
for (k in 1:n){
  predicted <- knn(train = knTng[,2:14],
                   test = knTst[,2:14],
                   cl=cl,
                   k)
  sum.error <- sum(abs(as.numeric(predicted) - as.numeric(actualRnk)))
  misclassification.rate[k,1] <- k
  misclassification.rate[k,2] <- sum.error
}
# visualize the different values for k
print(paste("Min",min(misclassification.rate[,2])))
View(misclassification.rate)
plot(misclassification.rate[,2], ylab = "Misclass Rate", xlab = "Value K")

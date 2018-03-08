### SCRAPR
library(XML)
library(stringr)
library(httr)

years <- seq(from=1920,to=2017)
# remove 2015 from the list, since this was a lockout year (season did not happen)
years <- years[years!=2005]

urls.list <- c()
for(year in years){
  urls.list <- c(urls.list, paste("http://www.hockey-reference.com/leagues/NHL_",year,"_games.html", sep=''))
}

nhl<-NULL
for (i in 1:length(urls.list)){
  table <- GET(urls.list[i])
  tables <- readHTMLTable(rawToChar(table$content))
  n.rows <- unlist(lapply(tables, function(t) dim(t)[1]))
  temp<-tables[[which.max(n.rows)]]
  nhl<-rbind(nhl,temp)
  print(paste(years[i], ': Complete'))
}

names(nhl)<-c("Date","Visitor","VisGoals","Home","HomeGoals","OTCat","Notes")
table(nhl$OTCat)
nhl<-nhl[nhl$OTCat!="Get Tickets",]
nhl$OT<-nhl$OTCat=="OT"|nhl$OTCat=="SO"

write.csv(nhl, file = 'head_to_head_1920_2017.csv', row.names = F)


table <- GET('https://www.hockey-reference.com/leagues/NHL_2018.html#all_stats')
tables <- readHTMLTable(rawToChar(table$content))
n.rows <- unlist(lapply(tables, function(t) dim(t)[1]))
temp<-tables[[which.max(n.rows)]]

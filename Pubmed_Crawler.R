# environment requirement ================================
# install.packages("wordcloud2")
# install.packages("svDialogs")
# install.packages("rJava")
# install.packages("RSelenium")
# install.packages("rvest")
# install.packages("RCurl") # package Rwebdriver depends on RCurl and RJSONIN
# install.packages("RJSONIO") # package Rwebdriver depends on RCurl and RJSONIN
# devtools::install_github(repo= "crubba/Rwebdriver") # package Rwebdriver depends on RCurl and RJSONIN
# install.packages("webshot")
# install.packages("wordcloud2")
# install.packages("htmlwidgets")
# webshot::install_phantomjs(force = TRUE)

# CSS/Xpath setting ====================================
# set the css/xpath of information 
# ! Do NOT modify these parameters unless U know what UR doing !
## the URL of pubmed
url.pubmed <- "https://www.ncbi.nlm.nih.gov/pubmed/?term="
## the number of results
ind.numberPaper <- '//*[@id="maincontent"]/div/div[3]/div[1]/h3/text()'
## the buttom of nextPage
ind.nextPage = '//*[@title="Next page of results"]'
## the buttom of 200 results per page
ind.perPage1 <- '//ul[@class="inline_list left display_settings"]/li[3]/a/span[4]'
ind.perPage2 <- '#display_settings_menu_ps > fieldset > ul > li:nth-child(6) > label'
## the buttom of filtering results of 5 recent years
ind.filterYear.5 <- '#_ds1 > li > ul > li:nth-child(1) > a'
## the buttom of filtering results of 10 recent years
ind.filterYear.10 <- '#_ds1 > li > ul > li:nth-child(2) > a'
## the information-index of the title
ind.title <- '//div[@class="rprt"]/div[2]/p[@class="title"]'
## the information-index of the journal
ind.journal <- '//div[@class="rprt"]/div[@class="rslt"]/div/p[@class="details"]'
## the information-index of the publish Date
ind.date <- '//div[@class="rprt"]/div[@class="rslt"]/div/p[@class="details"]'

# Functions Definding ================================
# define a function to extract the number of results
ItemNumer <- function(ind = ind.numberPaper, webpage){
  itemNumber <- html_node(webPage, xpath = '//*[@id="maincontent"]/div/div[3]/div[1]/h3/text()') %>% 
    html_text() %>% str_match(pattern = '[0-9]*$') %>% as.numeric()
  return(itemNumber)
}
# define a function to re-input the keywords
ReinputKeywords <- function(){
  newWords <- readline('new input：')
  return(newWords)
}
# define two functions to filter results
Filter5Year <- function(ind = ind.filterYear.5, browser=mocBrowser){
  recentYears <- browser$findElement(using = "css selector", ind)
  recentYears$clickElement()}
Filter10Year <- function(ind = ind.filterYear.10, browser=mocBrowser){
  recentYears <- browser$findElement(using = "css selector", ind)
  recentYears$clickElement()}
# define a function to modify the keywords
ShapeKeywords <- function(words){
  words <- words %>% 
    stringr::str_replace_all(pattern = "[:space:]", replacement = '+') %>% # replace the space with '+' signal
    stringr::str_replace_all(pattern = ",", replacement = '%2C') %>% # replace the ',' with '%2C'
    stringr::str_replace_all(pattern = '\\[', replacement = '%5B') %>% # replace the '['
    stringr::str_replace_all(pattern = '\\]', replacement = '%5D') # # replace the ']'
  return(words)
}
# define a function to turn pages
NextPage <- function(valueInd = ind.nextPage, browser){
  tryCatch({
    nextPage <- browser$findElement(using ='xpath', value = valueInd)
    nextPage$clickElement()
  }, error = function(e){
    svDialogs::dlg_message(c("This is the last page"))
  })
}
# define a function to get information
GetInfo <- function(webpage){
  paperTitles <- rvest::html_nodes(webPage, xpath = ind.title) %>% rvest::html_text() %>% stringr::str_trim()
  journalNames <- rvest::html_nodes(webPage, xpath = ind.journal) %>% 
    rvest::html_text() %>% lapply(., function(e){stringr::str_split(e, pattern = "[.]")[[1]][1]}) %>% unlist()
  publishDate <- rvest::html_nodes(webPage, xpath = ind.date) %>% 
    rvest::html_text() %>% stringr::str_match(pattern = "[:digit:]+") %>% as.numeric()
  assembledResults <- data.frame(paperTitles, journalNames, publishDate) 
  return(assembledResults)
}

# Library loading ====================================
## Remeber. Running the following in your windows CMD before loading RSelenium
#java -Dwebdriver.chrome.driver="D:\Rproject\wordCloud\crawlerRequirements\geckodriver.exe" -jar D:\Rproject\wordCloud\crawlerRequirements\selenium-server-standalone-3.141.59.jar
## general used packages 
library(readxl)
library(tidyverse)
library(stringr)
library(svDialogs) # show dialogs
## Tools for wordcloud
library(webshot)
library(wordcloud2)
library(htmlwidgets)
library(rJava) # if you want to load this package successfully, make sure the Java JRE & JDK were installed correctly
## Tools for net-spider
library(rvest)
library(Rwebdriver)
library(RSelenium)

# inputting global variables  ======================================
openCMD <- 'no'
while (openCMD == 'no') {
  openCMD <- dlg_message(c('Is the Selenuim running in your CMD? like: java -Dwebdriver.chrome.driver="D:\\Rproject\\wordCloud\\crawlerRequirements\\geckodriver.exe" -jar D:\\Rproject\\wordCloud\\crawlerRequirements\\selenium-server-standalone-3.141.59.jar
\n'), "yesno")$res
}
# get the keywords
dlg_message("Note. This pipeline was only been tested on Windows Platform")
keyWords <- dlg_input("Please Input the Keyword(s):")$res # the '+' represents a white space in the keywords
# get the filtering index
filterYears <- dlg_message(message = "Do you want to filter the result for recent 5 or 10 years?", "yesno")$res
if (filterYears == 'yes') {
  filterYears <- dlg_input(message = "Which years you want for filter (input 5 or 10)", default = "5")$res
}
# get the output path
outpath <- dlg_dir(default = getwd(), title = "Where to save the results?")$res
getname <- dlg_input("give a name to the results:", default = "mytest")$res
# reshape the inputs
csvname <- paste(outpath, '\\', getname, '.csv', sep = '')
plotname <- paste(outpath, '\\', getname, '.pdf', sep = '')
plotname.html <- paste(outpath, '\\', getname, '.html', sep = '')
keyWords <- ShapeKeywords(keyWords)
targetUrl <- paste(url.pubmed, keyWords, sep = '') # the Url of target website
# setup the browser
mocBrowser <- remoteDriver(
  browserName <- "firefox", # in this example, we use firefox
  remoteServerAddr = "localhost", # this parameter can keep as defualt
  port = 4444L # this parameter can keep as defualt
)
# Abandon code
# journalNames <- html_nodes(webPage, xpath = '//div[@class="rprt"]/div[@class="rslt"]/div/p[@class="details"]/span') %>% html_text() %>% str_trim() %>% unlist()


# Main() ================================================
# open the browser
mocBrowser$open()
# navigate to the target website
mocBrowser$navigate(targetUrl)
webPage <- read_html(mocBrowser$getPageSource()[[1]][1])
while (is.na(ItemNumer(webpage = webPage))) {
  print('No Item was found with the keyword(s), please re-input:')
  keyWords <- ReinputKeywords()
  keyWords <- ShapeKeywords(keyWords)
  targetUrl <- paste(url.pubmed, keyWords, sep = '')
  mocBrowser$navigate(targetUrl)
  webPage <- read_html(mocBrowser$getPageSource()[[1]][1])
}
# extenting the results to 200 per pages
perPage.s1 <- mocBrowser$findElement(using = 'xpath', ind.perPage1)
perPage.s1$clickElement()
perPage.s2 <- mocBrowser$findElement(using = 'css selector', ind.perPage2)
perPage.s2$clickElement()
# flitering the results
switch (filterYears,
  "5" = Filter5Year(),
  "10" = Filter10Year()
)
webPage <- read_html(mocBrowser$getPageSource()[[1]][1])
if (length(html_nodes(webPage, xpath = ind.nextPage))) {
  infoCollect <- GetInfo(webpage = webPage)
  # turning page
  NextPage(browser = mocBrowser)
  repeat{
    webPage <- read_html(mocBrowser$getPageSource()[[1]][1])
    infoCollect <- rbind(infoCollect, GetInfo(webpage = webPage))
    # turning to the next page
    NextPage(browser = mocBrowser)
    if (!length(html_nodes(webPage, xpath = ind.nextPage))) {
      break()
    }
  }
}else {
  Sys.sleep(4)
  infoCollect <- GetInfo(webpage = webPage) 
}
mocBrowser$closeall()
svDialogs::dlg_message(paste('The numer of search results are:', ItemNumer(), sep = ' '))
# save the result data.frame to csv file
write.csv(infoCollect, file = csvname)
# result visualization by journal published frequency ==================
ss <- wordcloud2(table(infoCollect$journalNames), size = 1, rotateRatio = 0)
saveWidget(ss,plotname.html,selfcontained = F)
webshot(plotname.html,plotname, delay =5, vwidth = 480, vheight=480)
browseURL(plotname.html) # open html with system default browser
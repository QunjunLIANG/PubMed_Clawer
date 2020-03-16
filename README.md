# PubMed_Clawer
A R-based clawer which could extract the paper titles and journal names from PubMed.

I wrote this script for checking the publish of our group. But I decided to git it when I realized it could be helpful for PhD applicants to know their ideal superviors and those who are struggling with meta-analysis.

# The features of PubMed_Clawer
1. It allows you to input keywords in Rstudio instead of approaching the pubmed website to start your search.
2. PubMed_Clawer collects the paper titles, journal names and publish Date, then write them down into a CSV file.
3. PubMed_Clawer also does some visualization, which use wordcloud to show the frequency of journal names.

# Notes before using
1. PubMed_Clawer requires *[selenium](https://www.selenium.dev/downloads/)* to control the browser, please make sure selenium has been install properly in your OS.
2. PubMed_Clawer also needs the java environment to run rJAVA.
3. PubMed_Clawer uses the GUI in Rstudio, so do not run PubMed_Clawer with other IDEs.
4. PubMed_Clawer just be tested on windows 10 platform.

# Contact me
I am not a high-level player of R, if you have any comment on this project, please let me know.

My Email address: <liangqunjun@foxmail.com>

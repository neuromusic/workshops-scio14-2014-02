
## ----textming_plos,  warning=FALSE, message=FALSE------------------------
library(rplos)
library(tm)
library(wordcloud)
library(ggplot2)


###  We can get the full text for a plos article with rplos.
## Grab full text
a_text <- searchplos("evolution", fields =c('everything'), limit = 10)

### Now we need to make a term document matrix.


# Create a corpus of words
plos_corpus <- Corpus(VectorSource(a_text$everything))

# Here we'll lowercase everything, strip punctionation, and remove stop words

plos_corpus <- tm_map(plos_corpus, tolower)
plos_corpus <- tm_map(plos_corpus, removePunctuation)
plos_corpus <- tm_map(plos_corpus, removeNumbers)

### Create stopwords list and strip them out
myStopwords <- c(stopwords('english'), "available", "via")
plos_corpus <- tm_map(plos_corpus, removeWords, myStopwords)


### Stem the words
dictCorpus <- plos_corpus
plos_corpus <- tm_map(plos_corpus, stemDocument)
plos_corpus <- tm_map(plos_corpus, stemCompletion, dictionary=dictCorpus)


### Next we create out term document matrix
plos_tdm <- TermDocumentMatrix(plos_corpus, control = list(minWordLength = 2))

### We can now do fun things
## Check and see what frequent terms were found
findFreqTerms(plos_tdm, lowfreq=30)



### Find associations
findAssocs(plos_tdm, 'data', 0.75)

### Now let's try and make a word cloud!
# convert
m <- as.matrix(plos_tdm)

v <- sort(rowSums(m), decreasing=TRUE)
myNames <- names(v)
d <- data.frame(word=myNames, freq=v)
pal <- colorRampPalette(c("red","blue"))(10)
wordcloud(d$word, d$freq, min.freq=10,colors=pal,random.order=FALSE)



## ----pubmed mining, warning=FALSE, message=FALSE-------------------------
pmids <- entrez_search(db="pubmed",term=c("arabidopsis"), mindate=2010, maxdate=2012, retmax=50)$ids

out <-fetch_in_chunks(pmids)

### This object structure is admittedly byzantine, but this works to get all the abstracts out

abs_vec <- vector()
for(i in 1:length(out)){
abs_vec <- c(abs_vec,out[[i]]$MedlineCitation$Article$Abstract$AbstractText)}

## Now we can apply the same techniques to make our word cloud


# Create a corpus of words
pubmed_corpus <- Corpus(VectorSource(abs_vec))

# Here we'll lowercase everything, strip punctionation, and remove stop words

pubmed_corpus <- tm_map(pubmed_corpus, tolower)
pubmed_corpus <- tm_map(pubmed_corpus, removePunctuation)
pubmed_corpus <- tm_map(pubmed_corpus, removeNumbers)

### Create stopwords list and strip them out
myStopwords <- c(stopwords('english'),"within","nonprocessed")
pubmed_corpus <- tm_map(pubmed_corpus, removeWords, myStopwords)


### Stem the words  ### This can take a long time, and maybe you don't want to do it
dictCorpus <- pubmed_corpus
pubmed_corpus <- tm_map(pubmed_corpus, stemDocument)
pubmed_corpus <- tm_map(pubmed_corpus, stemCompletion, dictionary=dictCorpus)

pubmed_tdm <- TermDocumentMatrix(pubmed_corpus, control = list(minWordLength = 3))

### Do this to remove sparse terms

#pubmed_tdm <- removeSparseTerms(pubmed_tdm, 0.4)


m <- as.matrix(pubmed_tdm)

v <- sort(rowSums(m), decreasing=TRUE)
myNames <- names(v)
d <- data.frame(word=myNames, freq=v)
pal <- colorRampPalette(c("red","blue"))(10)
wordcloud(d$word, d$freq, scale=c(2.5,.1) , min.freq=1,colors=pal,random.order=FALSE)




## ----microarray , warning=FALSE, message=FALSE---------------------------
### Create a dense matrix and melt it
pubmed_dense <- as.matrix(pubmed_tdm)
### In case document numbers weren't assigned
colnames(pubmed_dense) <- 1:dim(pubmed_dense)[2]

pubmed_dense = melt(pubmed_dense, value.name = "count")

### The resulting plot will be unreadable so let's trim some terms out.
## Trim out terms that are mentioned less than 10 times

highF_words <- findFreqTerms(pubmed_tdm, lowfreq=10)

pubmed_dense <- pubmed_dense[pubmed_dense$Terms %in% highF_words,]


ggplot(pubmed_dense, aes(x = Docs, y = Terms, fill = log10(count))) +
     geom_tile(colour = "white") +
     scale_fill_gradient(high="#FF0000" , low="#FFFFFF")+
     ylab("") +
     theme(panel.background = element_blank()) +
     theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())




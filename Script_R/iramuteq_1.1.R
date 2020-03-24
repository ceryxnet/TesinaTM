# Install
install.packages("RColorBrewer")
install.packages("formattable")
install.packages("Xplortext")
install.packages("SnowballC")
install.packages("wordcloud")
install.packages("textstem")
install.packages("vegan")
install.packages("klaR")
install.packages("lsa")
install.packages("tm")
install.packages("udpipe")

library(RColorBrewer)
library(formattable)
library(SnowballC)
library(wordcloud)
library(Xplortext)
library(textstem)
library(cluster)   
library(readxl)
library(vegan)
library(dplyr)
library(klaR)
library(lsa)
library(tm)
library(udpipe)


#####################################################################################################
# B.1 Creazione di nuvole di parole: una nuvola per le n parole piu' frequenti per la strategia 1 e 2, 
# B.1.1 creazione di una o piu' nuvole che tengano conto della sovrapposizione delle parole (il numero n dovru' essere 
#       scelto in funzione dei dati raccolti).
# Commentare i risultati.

# B.2 Creazione di una mappa di parole per ciascuna strategia di analisi, a partire da una tabella lessicale 
#     (parole X valutazione in stelle). Commentare i risultati.

# B.3 Applicare una o piu' tecniche di clustering, con l'obiettivo di classificare i contenuti dei commenti. 
# Illustrare i risultati, anche in termini comparativi rispetto alle strategie di analisi utilizzate.
#####################################################################################################

# Pulizia di tutte le variabili nel workspace
rm(list=ls())

############################################################
# Percorso locale che contiene i file di input e di output 
# deve essere cambiato in base alla propria workspace locale
input_path  <- "~/Desktop/Master/Text Mining/TextMining/"
output_path <- "~/Desktop/Master/Text Mining/TextMining/iramuteq"


## crea le sottocartelle nelle quali verranno salvati gli output 
dir.create(output_path, recursive = TRUE, showWarning=FALSE)
############################################################

# File di input
S1_msg_file    <- "Testaccio_5_0_message.csv"
S2_msg_file    <- "Testaccio_50_20_message.csv"

# file di output 
f_wordcloud         <- "Wordcloud"
f_barplot           <- "barplot"
f_wordcloud         <- "wordcloud"
f_comparison.cloud  <- "comparison.cloud"
f_commonality.cloud <- "commonality.cloud"
f_cluster         <- "cluster"

S1_msg_by_name <- "Testaccio_5_0_message_by_name.csv"
S1_msg_irmtq   <- "Testaccio_5_0_message_irmtq.txt"
s1_msg_by_name_irmtq   <- "Testaccio_5_0_message_by_name_irmtq.txt"

s2_msg_by_name <- "Testaccio_50_20_message_by_name.csv"
s2_msg_irmtq   <- "Testaccio_50_20_message_irmtq.txt"
s2_msg_by_name_irmtq   <- "Testaccio_50_20_message_by_name_irmtq.txt"



# Percorso locale che contiene il file con la lista delle stop word personalizzate
stp_wrd_file <- "stopwords-it.txt"

# Importo i dati in un dataframe
setwd(input_path)
msg_s1 <- read.csv(S1_msg_file, sep = "|", header=TRUE, encoding = "UTF-8")
msg_s2 <- read.csv(S2_msg_file, sep = "|", header=TRUE, encoding = "UTF-8")

#####################################################################################################
################## Prepara un vettore di stop word personalizzato ###################################
setwd(input_path)
own_stop = read.table(stp_wrd_file, stringsAsFactors = FALSE ,header = TRUE)
stop_vec <- as.character(own_stop[[1]])
head(stop_vec)
#####################################################################################################

setwd(output_path)
#####################################################################################################
### Strategia 1
# Genera un nuovo dataset ed accorpa i messaggi per ristorante
msg_s1_by_name <- group_by(msg_s1, name) %>%
  summarise(no_rating = round(mean(no_rating/10),2),
            message   = paste(message, collapse = " "))

# salva il nuovo dataframe su file in formato csv
#write.csv2(msg_s1_by_name, file=S1_msg_by_name, quote=TRUE, fileEncoding = "UTF-8")
#head(msg_s1_by_name, 1)

# Genera un nuovo file piatto in formato txt formattato per essere preso in ingresso al ptogramma
# di analisi IRAMUTEQ
# Struttura del messaggio per iramuteq
# **** *NAME_RESTNAME *NO_RATING_STAR
# \n
# message

# Prepara i campi chiave del file
START<-'****'
NAME<-'*NAME_'
RATING<-'*RATING_'
EMPTY<-'\n'

library(stringr)
# Costruisce le righe nel formato atteso da IRAMUTEQ concatenando le stringhe del dataframe in modo opportuno
# l'operazione viene eseguita sul dataframe originale dei messaggi
# il risultato viene salvato su file piatto
msg_s1_imtq <-paste(START, paste(NAME,gsub(' ', '', msg_s1$name), sep=''), 
                    paste(RATING, msg_s1$no_rating, sep=''), EMPTY, EMPTY, 
                    str_replace_all(msg_s1$message, "[^[:alnum:]]", " "), sep=' ')
fileConn<-file(S1_msg_irmtq)
writeLines(msg_s1_imtq, fileConn)
close(fileConn)

# Costruisce le righe nel formato atteso da IRAMUTEQ concatenando le stringhe del dataframe in modo opportuno
# l'operazione viene eseguita sul dataframe che contine i messaggi raggruppati per ristorante
# il risultato viene salvato su file piatto
# msg_s1_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s1_by_name$name), sep=''), paste(RATING, msg_s1_by_name$no_rating, sep=''), EMPTY, msg_s1_by_name$message, sep=' ')
# fileConn<-file(s1_msg_by_name_irmtq)
# writeLines(msg_s1_imtq2, fileConn)
# close(fileConn)

#msg_s1_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s1_by_name$name), sep=''), 
msg_s1_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s1_by_name$name), sep=''), 
                    paste(RATING, msg_s1_by_name$no_rating, sep=''), EMPTY, EMPTY, 
                    str_replace_all(msg_s1_by_name$message, "[^[:alnum:]]", " "), sep=' ')
fileConn<-file(s1_msg_by_name_irmtq)
writeLines(msg_s1_imtq2, fileConn)
close(fileConn)

# Genera un nuovo file identico all'originale ma con i campi nel formato accettato da IRAMUTEQ
#write.csv2(msg_s1, file=S1_msg_by_name, quote=TRUE, fileEncoding = "UTF-8")

#####################################################################################################
### Strategia 2

# Genera un nuovo dataset ed accorpa i messaggi per ristorante
msg_s2_by_name <- group_by(msg_s2, name) %>%
  summarise(no_rating = round(mean(no_rating/10),2),
            message   = paste(message, collapse = " "))

# salva il nuovo dataframe su file in formato csv
#write.csv2(msg_s2_by_name, file=S2_msg_by_name, quote=TRUE, fileEncoding = "UTF-8")
#head(msg_s2_by_name, 1)


# Genera un nuovo file piatto in formato txt formattato per essere preso in ingresso al ptogramma
# di analisi IRAMUTEQ
# Struttura del messaggio per iramuteq
# **** *NAME_RESTNAME *NO_RATING_STAR
# \n
# message

# Prepara i campi chiave del file
START<-'****'
NAME<-'*NAME_'
RATING<-'*RATING_'
EMPTY<-'\n'

library(stringr)
# Costruisce le righe nel formato atteso da IRAMUTEQ concatenando le stringhe del dataframe in modo opportuno
# l'operazione viene eseguita sul dataframe originale dei messaggi
# il risultato viene salvato su file piatto
msg_s2_imtq <-paste(START, paste(NAME,gsub(' ', '', msg_s2$name), sep=''), 
                    paste(RATING, msg_s2$no_rating, sep=''), EMPTY, EMPTY, 
                    str_replace_all(msg_s2$message, "[^[:alnum:]]", " "), sep=' ')
fileConn<-file(s2_msg_irmtq)
writeLines(msg_s2_imtq, fileConn)
close(fileConn)

# Costruisce le righe nel formato atteso da IRAMUTEQ concatenando le stringhe del dataframe in modo opportuno
# l'operazione viene eseguita sul dataframe che contine i messaggi raggruppati per ristorante
# il risultato viene salvato su file piatto
# msg_s2_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s2_by_name$name), sep=''), paste(RATING, msg_s2_by_name$no_rating, sep=''), EMPTY, msg_s2_by_name$message, sep=' ')
# fileConn<-file(s2_msg_by_name_irmtq)
# writeLines(msg_s2_imtq2, fileConn)
# close(fileConn)

#msg_s2_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s2_by_name$name), sep=''), 
msg_s2_imtq2 <-paste(START, paste(NAME,gsub(' ', '', msg_s2_by_name$name), sep=''), 
                     paste(RATING, msg_s2_by_name$no_rating, sep=''), EMPTY, EMPTY, 
                     str_replace_all(msg_s2_by_name$message, "[^[:alnum:]]", " "), sep=' ')
fileConn<-file(s2_msg_by_name_irmtq)
writeLines(msg_s2_imtq2, fileConn)
close(fileConn)

# Genera un nuovo file identico all'originale ma con i campi nel formato accettato da IRAMUTEQ
#write.csv2(msg_s2, file=S2_msg_by_name, quote=TRUE, fileEncoding = "UTF-8")

#####################################################################################################
#####################################################################################################
#####################################################################################################
# costruisco una funzione che prende in ingresso un pattern da ricercare nel testo e sostituire 
# con lo spazio
toSpace <- content_transformer(function (x , pattern ) gsub(pattern, " ", x))

# Funzione che opera una normalizzazione semplice dei commenti,
# in questa fase si procedere ad una pulizia del corpus eliminano le parole non necessarie, numeri 
# punteggiature e simboli.  
pre_processing<-function(corpus){

    # rimuovi la punteggiatura
  dfCorpus <- tm_map(corpus, removePunctuation)
  #inspect(dfCorpus1)
  
  # Converti il testo in minuscolo
  dfCorpus <- tm_map(dfCorpus, content_transformer(tolower))

  # Rimuovi le stopword in lingua italiana in aggiunta alle stop work inserite a mano
  dfCorpus <- tm_map(dfCorpus, removeWords, stopwords("italian"))
  dfCorpus <- tm_map(dfCorpus, removeWords, stop_vec)
  
  #rimuove i caratteri anomali
  dfCorpus <- tm_map(dfCorpus, toSpace, "[^[:alnum:]]")
  
  # Rimuovi i numeri
  dfCorpus <- tm_map(dfCorpus, removeNumbers)
  
  # Elimina gli spazi bianchi extra
  dfCorpus<-tm_map(dfCorpus, stripWhitespace)
  return (dfCorpus)
}

# Funzione che opera una normalizzazione morfologica sul corpus
norm_morf<-function(corpus){
  # dfCorpus1<-textstem::lemmatize_strings(dfCorpus1)
  dfCorpus <- tm_map(corpus, textstem::lemmatize_strings)
  #dfCorpus <- tm_map(dfCorpus, stemDocument, language = "italian") #decommentare per applicare la funzione di stemming
  
  # riunisce tutti i documenti contenuti nel cospus in un unico agglomerato.
  #  dfCorpus <- tm_map(dfCorpus, PlainTextDocument)
}

# La funzione prende in ingresso documento, calcola le frequenze delle parole e genera un diagramma 
#a basse sulle frequenze ed una nuvola di parole il risultato viene salvato su file
gen_wordcloud<-function(w, label, id, n){
  # Viene costrito il corpus
  corpus = Corpus(VectorSource(w))
  
  # Viene eseguito il pre-processing delle parole e la normalizzazione
  corpus <- pre_processing(corpus)
  corpus <- norm_morf(corpus)
  #corpus <- tm_map(corpus, PlainTextDocument)
  #inspect(df_corpus)
  #View(msg)
  
  # Inspect output
  #writeLines(as.character(corpus[[1]]))
  #length(df_corpus)
  
  # Build della matrice term-document, E' una tabella che contiene le frequenze delle parole contenute 
  # nel corpus, inomi delle colonne sono le parole e le lighe sono i documenti (messaggi dei ristoranti). 
  # Dal corpus dei messaggi, viene costruita la tdm (associazione parole frequenze) e poi viene
  # transformata in un oggetto matrice
  tdm <- TermDocumentMatrix(corpus) %>% as.matrix()
  
  # genera il vettore delle frequenze ordinate in modo decrescente
  v <- sort(rowSums(tdm),decreasing=TRUE)
  #head(v, 25)
  
  # genera il dataframe parole, frequenze
  d <- data.frame(word = names(v),freq=v)
  #head(d, 10)
  #summary(v)
  
  set.seed(1234)
  
  ### Costruisce il grafico a barre delle prime 20 parole piu' frequenti
  png(paste(id,'_',f_barplot, '_', label, '.png', sep=''), width = 800, height = 600)
  barplot(d[1:20, ]$freq, 
          las = 2, 
          names.arg = d[1:20, ]$word, 
          col = heat.colors(20),
          main = "Most frequent words", 
          ylab = "Word frequencies")
  dev.off()
  
  # Genera la nuvola delle parole piu frequenti, il risultato viene salvato su file
  png(paste(id,'_',f_wordcloud, '_', label, '.png', sep=''), width = 800, height = 600)
  wordcloud(words = d$word, 
            freq = d$freq, 
            min.freq = n, max.words=200, 
            random.order=FALSE, rot.per=0.35, 
            colors=brewer.pal(8, "Dark2"))
  dev.off()
}

# La funzione prende in ingresso documenti ed effettual in confronto, il risultato viene salvato
# su file
overlapping<-function(w1, w2, l1, l2, id){
  # Prepara i due dataset su due vettori collassando i documenti
  if (length(w1) < 1)
    return()
  if (length(w2) < 1)
    return()
  
  w1 = paste(w1, collapse=" ")
  w2 = paste(w2, collapse=" ")
  
  w1 <- removeWords(w1, stop_vec)
  w2 <- removeWords(w2, stop_vec)

  # Genera un corpus contenente i dataset per il rating basso e alto
  corpus = Corpus(VectorSource(c(w1, w2)))
  
  # Viene fatta la pulizia del corpus per tutte le parole
  corpus <- pre_processing(corpus)
  corpus <- norm_morf(corpus)
  #corpus <- tm_map(corpus, PlainTextDocument)
  
  # Prepara la tebella termini per documento
  tdm <- TermDocumentMatrix(corpus) %>% as.matrix()
  print(length(tdm))
  # Aggiunge le etichette per la comparazione
  colnames(tdm) <- c(l1,l2)
  
  set.seed(1234)
  
  # genera la word cloud per l'unione dei due dataset
  png(paste(id,'_',f_wordcloud, '_', l1, '_', l2, '.png', sep=""), width = 800, height = 600)
  wordcloud(corpus, max.words = 100, 
            colors = brewer.pal(6, "BrBG"), 
            random.order = FALSE)
  dev.off()
  
  # genera la nuvola dove si evidenziano le parole in comune tra i due rating
  png(paste(id,'_',f_comparison.cloud, '_', l1, '_', l2, '.png', sep=""), width = 800, height = 600)
  comparison.cloud(tdm, 
                   max.words = 100, 
                   random.order = FALSE, 
                   colors = c("blue", "red"), 
                   title.bg.colors="white",
                   title.size=3,
                   bg.color = "black")
  dev.off()
  
  # genera la nuvola dove si evidenziano le parole in comune tra i due rating
  png(paste(id,'_',f_commonality.cloud,'_', l1, '_', l2, '.png', sep=""), width = 800, height = 600)
  commonality.cloud(tdm,
                    max.words = 100, 
                    random.order = FALSE, 
                    colors = brewer.pal(4, "Dark2"))
  dev.off()
}


# La funzione confronta due liste di messaggi suddivisi tra quelli con con un rating basso e quelli
# con un rating alto. Il risultato viene salvato su file.
sentiment_comparison<-function(msg_low, msg_high, lab1, lab2, id){
  
  # Prepara i due dataset su due vettori collassando i documenti
  low  = paste(msg_low, collapse=" ")
  high = paste(msg_high, collapse=" ")

  low  <- removeWords(low, stop_vec)
  high <- removeWords(high, stop_vec)
  
  # Genera un corpus contenente i dataset per il rating basso e alto
  corpus = Corpus(VectorSource(c(low, high)))
  
  # Viene fatta la pulizia del corpus per tutte le parole
  corpus <- pre_processing(corpus)
  corpus <- norm_morf(corpus)
  #corpus <- tm_map(corpus, PlainTextDocument)

  # Prepara la tebella termini per documento
  tdm <- TermDocumentMatrix(corpus) %>% as.matrix()
  
  # Aggiunge le etichette per la comparazione
  colnames(tdm) <- c(lab1,lab2)
  
  # genera la word cloud per l'unione dei due dataset
  png(paste(id,'_',f_wordcloud, '_', lab1, '_', lab2, '.png', sep=''), width = 800, height = 600)
  set.seed(1234)
  wordcloud(corpus, max.words = 100, 
            colors = brewer.pal(6, "BrBG"), 
            random.order = FALSE)
  dev.off()
  
  # genera la nuvola dove si evidenziano le parole piu' freuqenti per i due rating
  png(paste(id,'_',f_comparison.cloud, '_', lab1, '_', lab2, '.png', sep=''), width = 800, height = 600)
  comparison.cloud(tdm,
                   max.words = 100, 
                   random.order = FALSE, 
                   colors = c("blue", "red"), 
                   title.bg.colors="white",
                   title.size=2.5,
                   bg.color = "black")
  dev.off()
  
  # genera la nuvola dove si evidenziano le parole in comune tra i due rating
  png(paste(id,'_',f_commonality.cloud, '_', lab1, '_', lab2, '.png', sep=''), width = 800, height = 600)
  commonality.cloud(tdm,
                    max.words = 100, 
                    random.order = FALSE, 
                    colors = brewer.pal(4, "Dark2"))
  dev.off()
}

# La funzione genera un cluster gerarchico prendendo in ingresso una matrice delle distanze e la tipologia 
# di metodo che si vuole applicare
hirerarchical_cluster<-function(m_dist,f_method, f_name, n_kluster, id){
  png(paste(id,'_',f_name, '_', f_method, '.png', sep=''), width = 800, height = 600)
  fit <- hclust(m_dist , method=f_method, members = NULL)
  cofen_corr <- round(cor(m_dist, cophenetic(fit)),3)
  title <- paste("\nCluster Dendrogram", "\nMethod:", fit$method,"- Distance:",fit$dist.method, "\nCofenetic Correlation:", cofen_corr)
  plot(fit, main = title)
  rect.hclust(fit, k = n_kluster, border = "red")
  dev.off()
  return(fit)
}

# La funzione genera una tabella contenente le informaizoni lessicografiche costruita analizzando il dataframe
# contenete tutti i messaggi.
lexicometric<-function(w){
  #w<-msg_s1$message
  # Viene costrito il corpus
  corpus = Corpus(VectorSource(w))
  
  # Viene eseguito il pre-processing delle parole e la normalizzazione
  corpus <- pre_processing(corpus)
  corpus <- norm_morf(corpus)
  
  tdm <- TermDocumentMatrix(corpus) %>% as.matrix()
  
  # genera il vettore delle frequenze ordinate in modo decrescente
  l<- length(w)
  v <- sort(rowSums(tdm),decreasing=TRUE)
  d <- data.frame(word = names(v),freq=v)
  h <- d %>% filter(freq == 1) %>% nrow()
  v.N     <- sum(d['freq']) # Ttotale delle occorrenze (N)
  v.V     <- length(v)      # Totale delle forme grafiche (V) 
  v.lex   <- v.V/v.N*100    # Ricchezza lessicale (V/N*100)
  v.hapax <- (d %>% filter(freq == 1) %>% nrow())/v.V*100 # Percentuale di hapax (len(h)/V*100)
  v.f_avg <- v.N/v.V           # Frequenza media generale (N/V)
  v.guiraud   <- v.V/sqrt(v.N) # Guiraud index (V/sqr(N))
  
  lexical <- c('N. of messages', 'Total word count (tokens, N)', 'N. of different graphic forms (types, V)', 'Complexity Factor (lexical density, V/N*100)', 'N. of Hapax (V1)','Hapax Percentage (H=V1/V*100)', 'General Average Frequency (N/V)', "Guiraud Index (V/sqrt(N))")
  value   <- c(l, round(v.N,2), round(v.V, 2), round(v.lex, 2), h, round(v.hapax, 2), round(v.f_avg, 2), round(v.guiraud, 2))
  details <- data.frame(lexical, value)
  colnames(details)<- c("Lexicometric measures", "Values")
  return(details)
}

#####################################################################################################
################################# MISURE LESSICOMETRICHE ###########################################
#####################################################################################################
################### Strategia 1
s1_ret <- lexicometric(msg_s1_by_name$message)
formattable(s1_ret)

################### Strategia 2
s2_ret <- lexicometric(msg_s2_by_name$message)
formattable(s2_ret)

#####################################################################################################
################################## B. 1 #############################################################
#####################################################################################################
# B.1 Creazione di nuvole di parole: una nuvola per le n parole piu' frequenti per la strategia 1 e 2, 


setwd(output_path2)
################### Strategia 1
gen_wordcloud(msg_s1_by_name$message, 's1', '01', 20)

################### Strategia 2
gen_wordcloud(msg_s2_by_name$message, 's2', '02', 20)


# ############### Esplorare i termini piu' frequenti e le loro associazioni ###############
# # E' possibile avere una vista dei termini piu' frequenti dalla matrice dei termini-documento. 
# # Mostra le parole con almeno 4 occorrenze
# findFreqTerms(tdm_s1, lowfreq = 4)
# findFreqTerms(tdm_s2, lowfreq = 4, highfreq = 7)
# 
# # Analizza le associazioni fra i termini piu frequenti (i.e., termini piu' correlati) usa la funzione. 
# # Mostra quali parole sono piu' associate con la parola "molto"
# findAssocs(tdm_s1, terms = "molto", corlimit = 0.3)
# findAssocs(tdm_s2, terms = "molto", corlimit = 0.3)

#####################################################################################################
#####################################################################################################
#####################################################################################################
# Il dataset viene suddiviso in base al numero di rating; da 10 a 50. quindi vengono fatti i confronti
# 10 con 20, 20 con 30, 30 con 40, 40 con 50

df_s1_10 <- msg_s1_by_name %>% filter(no_rating < 2.00)
df_s1_20 <- msg_s1_by_name %>% filter(no_rating >= 2.00) %>% filter(no_rating < 3.00)
df_s1_30 <- msg_s1_by_name %>% filter(no_rating >= 3.00) %>% filter(no_rating < 4.00)
df_s1_40 <- msg_s1_by_name %>% filter(no_rating >= 4.00) %>% filter(no_rating < 5.00)
df_s1_50 <- msg_s1_by_name %>% filter(no_rating >= 5.00)

###### Strategia 1; genera i dataframe raggruppando i messaggi in base al rating
df_s2_10 <- msg_s2_by_name %>% filter(no_rating < 2.00)
df_s2_20 <- msg_s2_by_name %>% filter(no_rating >= 2.00) %>% filter(no_rating < 3.00)
df_s2_30 <- msg_s2_by_name %>% filter(no_rating >= 3.00) %>% filter(no_rating < 4.00)
df_s2_40 <- msg_s2_by_name %>% filter(no_rating >= 4.00) %>% filter(no_rating < 5.00)
df_s2_50 <- msg_s2_by_name %>% filter(no_rating >= 5.00)

################################## B. 1.1 ###########################################################
#####################################################################################################
# B.1.1 creazione di una o piu' nuvole che tengano conto della sovrapposizione delle parole 
#       (il numero n dovra' essere scelto in funzione dei dati raccolti).

setwd(output_path)
#####################################################################################################
######## Strategia 1
overlapping(df_s1_10$message, df_s1_20$message, 's1_10', 's1_20', '03')
overlapping(df_s1_20$message, df_s1_30$message, 's1_20', 's1_30', '04')
overlapping(df_s1_30$message, df_s1_40$message, 's1_30', 's1_40', '05')
overlapping(df_s1_40$message, df_s1_50$message, 's1_40', 's1_50', '06')

#####################################################################################################
######## Strategia 2

overlapping(df_s2_10$message, df_s2_20$message, 's2_10', 's2_20', '07')
overlapping(df_s2_20$message, df_s2_30$message, 's2_20', 's2_30', '08')
overlapping(df_s2_30$message, df_s2_40$message, 's2_30', 's2_40', '09')
overlapping(df_s2_40$message, df_s2_50$message, 's2_40', 's2_50', '10')


#####################################################################################################
#####################################################################################################
#####################################################################################################
# suddivido il dataset in due; uno contenente tutti i messaggi con rating 50 ed uno contenente tutti 
# i messaggi con rating 10,20,30. Tengo fuori 40

###### Genera i dataframe per i rating piu bassi e piu' alto
df_s1_low  <- msg_s1_by_name %>% filter(no_rating < 4.00)
df_s1_high <- msg_s1_by_name %>% filter(no_rating > 4.00)

###### Genera i dataframe per i rating piu bassi e piu' alto
df_s2_low  <- msg_s2_by_name %>% filter(no_rating < 4.00)
df_s2_high <- msg_s2_by_name %>% filter(no_rating > 4.00)
#####################################################################################################

png('11_Hist_rating_s1.png', width = 800, height = 600)
hist(msg_s1_by_name$no_rating, main='Histogram Restaurant messages Strategy 1', xlab = "Rating")
dev.off()

png('12_Hist_rating_s2.png', width = 800, height = 600)
hist(msg_s2_by_name$no_rating, main='Histogram Restaurant messages Strategy 2', xlab = "Rating")
dev.off()

################################## B. 2 #############################################################
#####################################################################################################
# B.2 Creazione di una mappa (semantica) di parole per ciascuna strategia di analisi, a partire da 
#     una tabella lessicale (parole X valutazione in stelle). Commentare i risultati.

setwd(output_path)
#####################################################################################################
######## Strategia 1
sentiment_comparison(df_s1_low$message, df_s1_high$message, 's1_low', 's1_high', '13')

#####################################################################################################
######## Strategia 2
sentiment_comparison(df_s2_low$message, df_s2_high$message, 's2_low', 's2_high', '14')

#####################################################################################################
################################## B. 3 #############################################################
#####################################################################################################
# B.3 Applicare una o piu' tecniche di clustering, con l'obiettivo di classificare i contenuti dei commenti. 
# Illustrare i risultati, anche in termini comparativi rispetto alle strategie di analisi utilizzate.

#####################################################################################################
setwd(output_path)
######## Strategia 1

# Genera un corpus contenente i dataset per il rating basso e alto
df_corpus_s1 = Corpus(VectorSource(msg_s1_by_name$message))

# Viene fatta la pulizia del corpus per tutte le parole
df_corpus_s1 <- pre_processing(df_corpus_s1)
df_corpus_s1 <- norm_morf(df_corpus_s1)

# Prima di effettuare le operazioni per il cluster trasformo il corpus in una matrice documenti per termini
dtm_s1 <- DocumentTermMatrix(df_corpus_s1)

# Costruisce una matrice rimuovendo i termini sparsi che appaiono con una frequenza minore dell'8%, 
# cioe' un valore di "sparsity" superiore al 98%.
dtm_s1_m <- removeSparseTerms(dtm_s1, 0.78) %>% as.matrix()

# Uso il metodo della distanza coseno per misurare le distanze tra le parole
d_cos_s1 <- cosine(dtm_s1_m) %>% as.dist()

#distanza euclidea
d_eucli_s1 <- dist(t(dtm_s1_m), method="euclidian")   

# EUCLIDEAN
## confronttiamo i dendrogrammi con il coefficiente di correlazione cofenetico
f_c_s1 <- paste(f_cluster,"_euclidean_s1",sep="")
# Cluster completo costruito con distanza euclidea
fit_ec <- hirerarchical_cluster(d_eucli_s1, "complete", f_c_s1, 4, '15')
# Cluster completo costruito con distanza euclidea
fit_es <- hirerarchical_cluster(d_eucli_s1, "single", f_c_s1, 4, '16')
# Cluster gerarchico ward
fit_ew <- hirerarchical_cluster(d_eucli_s1, "ward.D2", f_c_s1, 4, '17')

#COSENO
## confronttiamo i dendrogrammi con il coefficiente di correlazione cofenetico
f_c_s1 <- paste(f_cluster,"_coseno_s1",sep="")
# Cluster gerarchico singolo
fit_cc <- hirerarchical_cluster(d_cos_s1, "complete", f_c_s1, 4, '18')
# Cluster gerarchico singolo costruto su distanza coseno
fit_cs <- hirerarchical_cluster(d_cos_s1, "single", f_c_s1, 4, '19')
# Cluster gerarchico ward
fit_cw <- hirerarchical_cluster(d_cos_s1, "ward.D2", f_c_s1, 4, '20')

#k-means
# generazione del cluster attraverso il kmeans; 4 cluster partendo da un valore iniziale di 100
f_c_s1 <- paste(f_cluster,'_kmeans_s1',sep='')
png(paste('21_', f_c_s1, '.png', sep=''), width = 800, height = 600)
kmeans4 <- kmeans(d_eucli_s1, centers = 4, nstart = 100)
clusplot(as.matrix(d_eucli_s1) , kmeans4$cluster , color=TRUE, shade=TRUE, labels =3, lines =0, main="kmeans clusplot ")
dev.off()

#####################################################################################################
setwd(output_path)
######## Strategia 2

# Genera un corpus contenente i dataset per il rating basso e alto
df_corpus_s2 = Corpus(VectorSource(msg_s2_by_name$message))

# Viene fatta la pulizia del corpus per tutte le parole
df_corpus_s2 <- pre_processing(df_corpus_s2)
df_corpus_s2 <- norm_morf(df_corpus_s2)

# Prima di effettuare le operazioni per il cluster trasformo il corpus in una matrice documenti per termini
dtm_s2 <- DocumentTermMatrix(df_corpus_s2)

# Costruisce una matrice rimuovendo i termini sparsi che appaiono con una frequenza minore dell'8%, 
# cioe' un valore di "sparsity" superiore al 98%.
dtm_s2_m <- removeSparseTerms(dtm_s2, 0.20) %>% as.matrix()

# Uso il metodo della distanza coseno per misurare le distanze tra le parole
d_cos_s2 <- cosine(dtm_s2_m) %>% as.dist()

#distanza euclidea
d_eucli_s2 <- dist(t(dtm_s2_m), method="euclidian")   

# EUCLIDEAN
## confrontiamo i dendrogrammi con il coefficiente di correlazione cofenetico
f_c_s2 <- paste(f_cluster,"_euclidean_s2",sep="")
# Cluster completo costruito con distanza euclidea
fit_ec <- hirerarchical_cluster(d_eucli_s2, "complete", f_c_s2, 4, '22')
# Cluster completo costruito con distanza euclidea
fit_es <- hirerarchical_cluster(d_eucli_s2, "single", f_c_s2, 4, '23')
# Cluster gerarchico ward
fit_ew <- hirerarchical_cluster(d_eucli_s2, "ward.D2", f_c_s2, 4, '24')

#COSENO
## confrontiamo i dendrogrammi con il coefficiente di correlazione cofenetico
f_c_s2 <- paste(f_cluster,"_coseno_s2",sep="")
# Cluster gerarchico singolo
fit_cc <- hirerarchical_cluster(d_cos_s2, "complete", f_c_s2, 4, '25')
# Cluster gerarchico singolo costruto su distanza coseno
fit_cs <- hirerarchical_cluster(d_cos_s2, "single", f_c_s2, 4, '26')
# Cluster gerarchico ward
fit_cw <- hirerarchical_cluster(d_cos_s2, "ward.D2", f_c_s2, 4, '27')

#k-means
# generazione del cluster attraverso il kmeans; 4 cluster partendo da un valore iniziale di 100
f_c_s2 <- paste(f_cluster,'_kmeans_s2',sep='')
png(paste('28_', f_c_s2, '.png', sep=''), width = 800, height = 600)
kmeans4 <- kmeans(d_eucli_s2, centers = 4, nstart = 100)
clusplot(as.matrix(d_eucli_s2) , kmeans4$cluster , color=TRUE, shade=TRUE, labels =3, lines =0, main="kmeans clusplot ")
dev.off()


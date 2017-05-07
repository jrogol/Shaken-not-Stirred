library(tm)
library(dplyr)

plots <- Corpus(DataframeSource(films %>% select(plot)))

plots <- tm_map(plots, removePunctuation)
plots <- tm_map(plots , stripWhitespace)
plots <- tm_map(plots, removeWords, stopwords("english"))
plots <- tm_map(plots, stemDocument, language = "english")

dtm <- DocumentTermMatrix(plots)

sparse <- removeSparseTerms(dtm, .04)
sparse$ncol

plots


library(tidytext)

tidy_plot <- films %>% 
  select(film, plot) %>% 
  unnest_tokens(word, plot) %>% 
  count(film, word) %>% ungroup()



total_words <- tidy_plot %>%
  group_by(film) %>% 
  summarize(total = sum(n))

data("stop_words")

tidy_plot <- left_join(tidy_plot, total_words) %>%
  anti_join(stop_words) %>%
  bind_tf_idf(term_col = word, document_col = film, n_col = n)

tidy_plot %>% group_by(film) %>% arrange(desc(tf_idf))

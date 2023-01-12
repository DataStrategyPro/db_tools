source('compare_db_to_ref.R')

con <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

# Setup sample data ----

random_NAs <- function(df,n){
  for (i in 1:n) {
    x = sample(1:nrow(df),1)
    y = sample(1:ncol(df),1)
    df[[x,y]] <- NA
  }
  for (i in 1:n) {
    x = sample(1:nrow(df),1)
    y = sample(1:c(1,2),1)
    df[[x,y]] <- "Other"
  }
  
  return(df)
}

df <- random_NAs(mpg,50)
df

# Copy to DB ----
copy_to(con, mpg, "mpg")
copy_to(con, df, "mpg_na")

# Example of DBPlyr Translation
tdf <- tbl(con,'mpg_na')
tdf %>% 
  mutate_at(vars(matches("m")),list(is_null = is.na)) %>% 
  mutate_at(vars(matches("d")),~case_when(. %in%  (allowable_values) ~ ., TRUE ~ 'Other')) %>% 
  sql_render()

# Run the tests
tests_run('ref_example/',con)
tests_summarise(glue("test_results/{lubridate::today()}/"))
                
DBI::dbDisconnect(con)


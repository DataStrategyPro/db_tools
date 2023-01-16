library(tidyverse)
library(dbplyr)
library(tidylog)
library(glue)
library(fs)

ref_to_sql <- function(df){
  names(df) <- tolower(names(df))
  table_name <- df %>% head(1) %>% pull(table_name)
  null_cols <- df %>% select(contains("_is_null")) %>% names()
  cols <- df %>% select(-any_of(c('table_name','note','notes'))) %>% names()
  
  sql <- glue("with q1 as (
              Select *,")
  
  # null columns
  for (column in null_cols){
    v <- unique(df[column])
    valid_values <- str_c("'",str_c(v,collapse = "','"),"'")
    sql <- glue("{sql} 
              CASE WHEN({str_sub(column,end = -9)} IS NULL) THEN 'IS_NULL' ELSE 'NOT_NULL' END AS {column},")
  }
  sql <- str_sub(sql,end = -2)
  sql <- glue("{sql}
              from {table_name}
              ), q2 as (Select ")
  # Standard columns
  for (column in cols){
    v <- unique(df[column])
    v <- v[v != 'Other']
    valid_values <- str_c("'",str_c(v,collapse = "','"),"'")
    sql <- glue("{sql} 
              CASE WHEN {column} in ({valid_values}) THEN {column}
              ELSE 'Other'
              END as {column},")
  }
  
  # From table
  sql <- glue("{str_sub(sql,end = -2)}  
              from q1)
              
              select 
              ")
  sql <- str_c(sql,str_c(cols,collapse = ','))
  sql <- glue("{sql}, count(*) n
              from q2
              group by 
              ")
  sql <- str_c(sql,str_c(cols,collapse = ','))
  
  return(sql)
}

compare_to_ref <- function(df_main,df_ref,compare_cols,...){
  names(df_main) <- tolower(names(df_main))
  names(df_ref) <- tolower(names(df_ref))
  df <- df_main %>% 
    mutate(.merge.x = 1) %>% 
    full_join(df_ref %>% mutate(.merge.y = 1),...) %>%
    mutate(Result = ifelse(is.na(.merge.x),'Fail', ifelse(is.na(.merge.y), 'Warning','Pass'))) %>%
    mutate(Result_Detail = ifelse(is.na(.merge.x),'Not in data', ifelse(is.na(.merge.y), 'Not in reference file','Pass'))) %>%
    replace_na(list(n=1)) %>% 
    mutate(Pct = n / sum(n)) %>% 
    select(-.merge.x,-.merge.y)
  return(df)
}

test_run <- function(file,con){
  test_name <- file %>% path_file() %>% path_ext_remove()
  df_ref <- read_csv(file) 
  sql <- ref_to_sql(df_ref) 
  db_result <- db_collect(con,sql)
  compare_result <- compare_to_ref(db_result,df_ref)
  fs::dir_create(glue("test_results/{lubridate::today()}"))
  compare_result %>% write_csv(glue("test_results/{lubridate::today()}/{test_name}_result.csv"))
}

tests_run <- function(folder,con){
  files <- dir_ls(folder)
  files %>% map(test_run,con)
}

test_summarise <- function(file){
  test_name <- file %>% path_file() %>% path_ext_remove()
  df <- read_csv(file)
  df <- df %>% 
    group_by(Result) %>% 
    summarise(n = sum(n), Pct = sum(Pct)) %>% 
    mutate(Test_Name = test_name) %>% 
    relocate(Test_Name)
  return(df)
}

tests_summarise <- function(folder){
  df <- dir_ls(folder) %>% 
    map_df(test_summarise)
  return(df)
}

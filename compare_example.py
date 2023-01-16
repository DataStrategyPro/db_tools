%run 'compare.py'

df1 = pd.DataFrame({
  'ID':['A','B','B','C','C',None],
  'Value':[1,2,2,3,3,6],
  'Detail':['Detailed',' columns',' that dont',' get summarised',' for diagnosing',' issues']})
df1
df2 = pd.DataFrame({'ID':['B','B','C','C','D',None],'Value':[2,2,4,4,5,6]})
df2

  
c1 = Comparison(df1,df2,['ID'],'Value')

c1.df1
c1.df2
c1.results
c1.result_summary
c1.df1_detail
c1.df2_detail
c1.suffixes

c1.df1_detail.groupby('Result').head(2)

# Match on multiple fields


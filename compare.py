import pandas as pd
import numpy as np

class Comparison:
  def __init__(self,df1,df2,join_on,diff_on,suffixes=['_x','_y'],precision=2):
    self.df1 = df1
    self.df2 = df2
    self.join_on = join_on
    self.diff_on = diff_on
    self.suffixes=suffixes
    self.precision=precision

    df1_summary = df1.groupby(join_on,dropna=False).agg({diff_on:sum})
    df2_summary = df2.groupby(join_on,dropna=False).agg({diff_on:sum})
    df = pd.merge(df1_summary,df2_summary,on=join_on,how='outer',indicator=True,suffixes=suffixes).reset_index()
    df = df.assign(Diff = lambda x: round(x[f"{diff_on}{suffixes[0]}"] - x[f"{diff_on}{suffixes[1]}"],precision))

    self.results = df.assign(Result = lambda x: np.where(x.Diff == 0, 'Match',np.where(x._merge == 'both','Mismatch',np.where(x._merge == 'left_only',f'Not in {suffixes[1]}',f'Not in {suffixes[0]}' ))))

    self.result_summary = self.results.groupby('Result').size().reset_index(name='n')

    self.df1_detail = pd.merge(df1,self.results,on=join_on,how='outer')
    self.df2_detail = pd.merge(df2,self.results,on=join_on,how='outer')


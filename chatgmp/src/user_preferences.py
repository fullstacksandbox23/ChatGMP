import pandas as pd
import numpy as np
import sys
import os
from stat import *

def load_df(file):
    return pd.read_excel(file)

def rename_values(df):
    # add qc under production
    # add qualified person
    df.loc[df['topic'] == 'General plant manager', 'topic'] = 'management'
    df.loc[df['topic'] == 'Quality Control', 'topic'] = 'qc'
    df.loc[df['topic'] == 'Quality Unit (QA)', 'topic'] = 'qa'
    df.loc[df['topic'] == 'Site manager', 'topic'] = 'management'
    df.loc[df['topic'] == 'Production process', 'topic'] = 'production'
    df.loc[df['question'].str.contains('train'), 'topic'] = 'training'
    df.loc[df['question'].str.contains('management review'), 'topic'] = 'review'
    df['topic'] = df['topic'].str.lower()
    return df

def generate_script(list_dfs):
    c = 0
    for df in list_dfs:
        df['detail'] = [len(i) for i in df.question]
        df_aggr = df.groupby('topic').agg({'question': 'count', 
                                           'detail': 'mean'}).reset_index()
        print("#pos(example_" + str(c) + ", {}, {}, {")
        for idx, (topic, count, detail) in enumerate(zip(df_aggr.topic, 
                                                         df_aggr.question, 
                                                         df_aggr.detail)):
            print("question_type(topic(" + str(idx) + "), " + topic + ").")
            print("number_questions(topic(" + str(idx) + "), " + str(count) + ").")
            if detail >= df_aggr.detail.mean():
                print("detail_preference(topic(" + str(idx) + "), " + str(2) + ").")
            else:
                print("detail_preference(topic(" + str(idx) + "), " + str(1) + ").")
            print()
        c += 1
        if (len(df.topic.unique())) == len(topics):
            print("}).")
        else:
            missing = list(set(topics) - set(df.topic.unique()))
            for idx_, miss in enumerate(missing):
                print("question_type(topic(" + str(idx+(idx_+1)) + "), " + miss + ").")
                print("number_questions(topic(" + str(idx+(idx_+1)) + "), 0).")
                print("detail_preference(topic(" + str(idx+(idx_+1)) + "), 0).")
                print()
            print("}).")
        print()

def ordering():
    # Create all possible combinations of the given examples
    # Ordering based on grade: 7, 3, 18, 9, 22
    print("#brave_ordering(example_0, example_2, <).")
    print("#brave_ordering(example_0, example_3, <).")
    print("#brave_ordering(example_0, example_4, <).")
    print("#brave_ordering(example_1, example_0, <).")
    print("#brave_ordering(example_1, example_2, <).")
    print("#brave_ordering(example_1, example_3, <).")
    print("#brave_ordering(example_1, example_4, <).")
    print("#brave_ordering(example_2, example_4, <).")
    print("#brave_ordering(example_3, example_2, <).")
    print("#brave_ordering(example_3, example_4, <).")
    print()
    
def rules():
    print("#modeo(1, question_type(var(topic), const(topic_preference)), (positive)).")
    print("#modeo(1, number_questions(var(topic), var(count)), (positive)).")
    print("#modeo(1, detail_preference(var(topic), var(level)), (positive)).")
    print("#modeo(1, var(level) > const(level)).")
    print("#weight(count).")
    print("#weight(1).")
    print("#constant(topic_preference, management).")
    print("#constant(topic_preference, training).")
    print("#constant(topic_preference, qa).")
    print("#constant(topic_preference, qc).")
    print("#constant(topic_preference, maintenance).")
    print("#constant(topic_preference, logistics).")
    print("#constant(topic_preference, production).")
    print("#constant(topic_preference, review).")
    print("#constant(level, 0).")
    print("#constant(level, 1).")
    print("#constant(level, 2).")
    print("#maxp(3).")
    #print("#maxv(3).")

def opener(path, flags):
    return os.open(path, flags, 0o777)

def save_file(path, list_dfs):
    os.umask(0)
    # Saving the reference of the standard output
    original_stdout = sys.stdout 
    
    with open(path, 'w+', opener=opener) as f:
        sys.stdout = f
        generate_script(list_dfs)
        ordering()
        rules()
        # Reset the standard output
        sys.stdout = original_stdout
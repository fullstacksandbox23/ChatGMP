import pandas as pd
import numpy as np
from transformers import AutoModelForQuestionAnswering, AutoTokenizer, pipeline, AutoModelWithLMHead, AutoModelForCausalLM
from sentence_transformers import SentenceTransformer, util
import time
import torch

def semantic_search(asked_question, data):
    model_search = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    with open(data) as f:
        data = json.load(f)

    similarity = []
    answers = []
    embedding_1 = model_search.encode(asked_question, convert_to_tensor=True)
    for idx, (question, answer) in enumerate(data.items()):
        embedding_2 = model_search.encode(question, convert_to_tensor=True)
        # Similarity of two documents
        similarity.append(util.pytorch_cos_sim(embedding_1, embedding_2)[0].numpy())
        answers.append(answer)
    most_similar = similarity.index(max(similarity))
    return answers[most_similar]

def compute_f1(prediction, truth):
    pred_tokens = prediction.split()
    truth_tokens = truth.split()
    # if either the prediction or the truth is no-answer then f1 = 1 if they agree, 0 otherwise
    if len(pred_tokens) == 0 or len(truth_tokens) == 0:
        return int(pred_tokens == truth_tokens)
    common_tokens = set(pred_tokens) & set(truth_tokens)
    # if there are no common tokens then f1 = 0
    if len(common_tokens) == 0:
        return 0
    prec = len(common_tokens) / len(pred_tokens)
    rec = len(common_tokens) / len(truth_tokens)
    return 2 * (prec * rec) / (prec + rec)

def cosine_similarity(prediction, truth):
    model_sim = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    
    embedding_1 = model_sim.encode(prediction, convert_to_tensor=True)
    embedding_2 = model_sim.encode(truth, convert_to_tensor=True)
    # Similarity of two documents
    similarity = util.pytorch_cos_sim(embedding_1, embedding_2)[0].cpu().numpy()
    return similarity[0]

def predict(question, model_name="google/flan-t5-base"):
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)    
   
    context = semantic_search(question)
    min_length = int(len(context.split())*0.8)
    input = f"QUESTION: {question} CONTEXT: {context}"
  
    encoded_input = tokenizer([input],
                                 return_tensors='pt',
                                 max_length=1024,
                                 truncation=False)#.to(device)
    #model = model.to(device)
    output = model.generate(input_ids = encoded_input.input_ids,
                            attention_mask = encoded_input.attention_mask,
                            num_beams=5,
                            #num_return_sequences=10,
                            max_length=int(len(context.split()))+1,
                            min_new_tokens=min_length,
                            penalty_alpha=0.6, 
                            top_k=4,
                            do_sample=True,
                            )
    output = tokenizer.decode(output[0], skip_special_tokens=True)
    return output

def calculate_metrics(question):
    context = semantic_search(question)
    output = predict(question)
    f1_score = compute_f1(output, context)
    similarity = cosine_similarity(output, context)
    return f1_score, similarity
from flask import Flask, render_template, request
from transformers import  AutoTokenizer, AutoModelForSeq2SeqLM, FalconForCausalLM
from sentence_transformers import SentenceTransformer, util
import json
import os
import numpy as np
import torch

app = Flask(__name__)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def semantic_search(asked_question):
    model_search = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    with open('data_gmp_clean_2103.json') as f:
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

def save_file(question, answer, dest_path):
    data = {}
    data[question] = answer
    with open(dest_path, 'a') as f:
        f.write(json.dumps([data]) + '\n')

# @app.route("/documents")
def show_document(doc_name):
    path = os.path.join(os.path.dirname(__file__), '../static/')
    file_path = os.path.join(path, f'{doc_name}.pdf')
    # os.startfile(f'{path}{doc_name}.pdf')  # Commented out for Docker compatibility
    print(f"Document path: {file_path}")  # For debugging
    return ""

def get_requested_document(cont):
    if 'I can show you the management review' in cont:
        print('Manag')
        show_document('Management Review No 3 minutes')
    elif 'I can show you our latest management review' in cont:
        print('Manag')
        show_document('Management Review No 3 minutes')
    elif 'I can show you the Management Review N.3' in cont:
        print('Manag')
        show_document('Management Review No 3 minutes')
    elif 'I can show you the quality assurance procedure' in cont:
        print('qa')
        show_document('Quality Assurance procedure')
    elif 'I will show you our QA procedure' in cont:
        print('qa')
        show_document('Quality Assurance procedure')
    elif 'I can show you the quality control procedure' in cont:
        print('qc')
        show_document('Quality Control procedure')
    elif 'contained in the QC procedure. So here we have a summary of the procedure' in cont:
        print('qc')
        show_document('Quality Control procedure')
    elif 'I can show you a calibration record' in cont:
        print('cal')
        show_document('Calibration Temp Test Sheet filled out')
    elif "I'll show you a real calibration record" in cont:
        print('cal')
        show_document('Calibration Temp Test Sheet filled out')
    elif 'I can show you the cleaning' in cont:
        print('cleaning')
        show_document('Cleaning check list Ferm tank filled out')
    elif 'I do have an example of cleaning' in cont:
        print('cleaning')
        show_document('Cleaning check list Ferm tank filled out')
    elif 'I can show you this cleaning checklist for a fermentor' in cont:
        print('cleaning')
        show_document('Cleaning check list Ferm tank filled out')
    elif 'I can show you a cleaning checklist' in cont:
        print('cleaning')
        show_document('Cleaning check list Ferm tank filled out')
    elif 'I can show you the internal audit' in cont:
        print('audit')
        show_document('Internal Audit Program procedure')
    elif 'I can show you the maintenance' in cont:
        print('maint')
        show_document('Maintenance procedure')
    elif 'I can show you the packaging' in cont:
        print('pack')
        show_document('Packaging and Storage procedure')
    elif 'I can show you the training program for operators procedure' in cont:
        print('tr')
        show_document('Training Program for Operators procedure')
    elif 'training program for operators document. And here you can see' in cont:
        print('tr')
        show_document('Training Program for Operators procedure') 
    elif 'I can show you our operator training plan' in cont:
        print('tr')
        show_document('Training Program for Operators procedure') 
    elif "I can show you the training for operators' procedure" in cont:
        print('tr')
        show_document('Training Program for Operators procedure')
    elif 'I can show you a training plan filled out' in cont:
        print('tr filled')
        show_document('Training Plan Ferm operator filled out')
    elif 'an example of a filled-out training plan for operators' in cont:
        print('tr filled')
        show_document('Training Plan Ferm operator filled out')
    elif 'we have a training plan. If you like, I can show you one for a specific operator' in cont:
        print('tr filled')
        show_document('Training Plan Ferm operator filled out')
    elif 'an example of a training record from an operator' in cont:
        print('tr filled')
        show_document('Training Plan Ferm operator filled out')
    elif 'I can show you a CAPA' in cont:
        print('CAPA')
        show_document('CAPA Report No 23')
    elif 'I can show you an example of a CAPA report' in cont:
        print('CAPA')
        show_document('CAPA Report No 23')
    else:
        pass
    return ""

def predict(question):
    model = AutoModelForSeq2SeqLM.from_pretrained("google/flan-t5-base")
    # model = FalconForCausalLM.from_pretrained("Rocketknight1/falcon-rw-1b")
    tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-base")    
    context = semantic_search(question)
    min_length = int(len(context.split())*0.8)
    # input = f"QUESTION: {question} CONTEXT: {context}"
    #input = f"Based on the CONTEXT, Please answer this QUESTION: QUESTION: {question} CONTEXT: {context}"
    input = f"Please improve the language used in the CONTEXT: {context}"
    #input = f"Please use the information provided in the CONTEXT: {context} to improve the language and answer this QUESTION: {question}"
    encoded_input = tokenizer([input],
                                return_tensors='pt',
                                max_length=1024,
                                truncation=False).to(device)
    model = model.to(device)
    output = model.generate(input_ids = encoded_input.input_ids,
                            attention_mask = encoded_input.attention_mask,
                            num_beams=5,
                            #num_return_sequences=10,
                            #max_length=int(len(context.split()))+1,
                            max_new_tokens=512,
                            #min_new_tokens=min_length,
                            penalty_alpha=0.6, 
                            top_k=4,
                            do_sample=False,
                            )
    output = tokenizer.decode(output[0], skip_special_tokens=True)
    output = output.replace('CONTEXT: ', '')
    save_file(question, output, "test_after.jsonl")
    print(context)
    print(output)
    get_requested_document(context)
    return output

@app.route("/")
def home():    
    return render_template("index.html")

@app.route("/get")
def get_bot_response():    
    userText = request.args.get('msg')  
    response = predict(userText)  
    return response

# @app.route('/chatgmp')
# def get_virtual_tutor():
#     return render_template("chatgmp.html")

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
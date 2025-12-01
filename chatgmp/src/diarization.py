from pyannote.audio import Pipeline
import torch
import pandas as pd
from transformers import WhisperProcessor, WhisperForConditionalGeneration, WhisperFeatureExtractor
import librosa

def diarization_pipeline(auth_token, mp3_file_path, diarization_file_path):
    pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-3.1",
        use_auth_token=auth_token).to(torch.device("cuda" if torch.cuda.is_available() else "cpu"))
    
    # apply pretrained pipeline
    diarization = pipeline(mp3_file_path, min_speakers=2, max_speakers=6)
    
    diarization_list = []
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        diarization_list.append((turn.start, turn.end, speaker))
    
    df = pd.DataFrame(diarization_list, columns=['start', 'end', 'speaker'])
    df.to_csv(diarization_file_path)
    return df

def speech_extraction(auth_token, mp3_file_path, diarization_file_path, speech_file_path, model_name="openai/whisper-large"):
    df = diarization_pipeline(auth_token, mp3_file_path, diarization_file_path)
    
    processor = WhisperProcessor.from_pretrained(model_name)
    model = WhisperForConditionalGeneration.from_pretrained(model_name)
    
    cc = []
    for start, end, speaker in zip(df.start, df.end, df.speaker):
        y, sr = librosa.load(mp3_file_path, sr=16000, offset=start, duration=(end-start))
        inputs = processor(y, return_tensors="pt", padding="max_length", sampling_rate=16000)
        input_features = inputs.input_features.cuda()
        generated_ids = model.generate(inputs=input_features)
        transcription = processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
        cc.append((speaker, transcription, start, end))
    
    df_results = pd.DataFrame(cc, columns=['speaker', 'transcription', 'start', 'end'])
    df_results['start'] = df_results['start'].round(2)
    df_results['end'] = df_results['end'].round(2)
    df_results.to_csv(speech_file_path, decimal='.')
    return df_results
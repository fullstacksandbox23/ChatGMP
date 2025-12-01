import librosa
import matplotlib.pyplot as plt
import moviepy.editor as mp
from mutagen.mp3 import MP3
from transformers import WhisperProcessor, WhisperForConditionalGeneration
from os import listdir
from os.path import isfile, join
import re

def extract_audio(video):
    v = re.findall(r"(.*?)\.mp4", video)[0]
    my_clip = mp.VideoFileClip(f"{path}{video}")
    my_clip.audio.write_audiofile(f"audios/2023/audio_group_{v}.mp3")
    
def calculate_length(video, extension):
    v = re.findall(f"(.*?)\.{extension}", video)[0]
    audio = MP3(f"audios/2023/audio_group_{v}.mp3")
    return round(audio.info.length)

def extract_text(video, length, processor, model, overlap, extension, 
                 audio_path="audios/2023/audio_group_"):
    v = re.findall(f"(.*?)\.{extension}", video)[0]
    intervals = list(range(0, length, (30-overlap))) 
    duration = [30]* int(len(intervals)-1)
    duration.append(length-intervals[-1])
    cc = []
    for intv, dur in zip(intervals, duration):
        try:
            # Load 30 seconds of a file, starting intv seconds in
            y, sr = librosa.load(f"{audio_path}{v}.mp3", sr=16000, offset=intv, duration=dur)
            inputs = processor(y, return_tensors="pt", padding="longest", sampling_rate=16000)
            input_features = inputs.input_features
            generated_ids = model.generate(inputs=input_features)
            transcription = processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            cc.append(transcription)
            with open(f"texts/2023/text_group_{v}2.txt", "a+") as f:
                f.write(f"{transcription}\n")   
        except (RuntimeError, NameError) as e:
            print(length-intv)

def run_extraction(video_files, done, model_name="openai/whisper-large"):
    done = []
    processor = WhisperProcessor.from_pretrained(model_name)
    model = WhisperForConditionalGeneration.from_pretrained(model_name)
    for video in video_files:
        if video not in done and video.endswith("mp4"):
            extract_audio(video)
            length = calculate_length(video, "mp4")
            extract_text(video, length, processor, model, 3, "mp4")
            done.append(video)
        elif video not in done and video.endswith("mp3"):
            audio = MP3(f"{path}{video}")
            length = round(audio.info.length)
            extract_text(video, length, processor, model, 3, "mp3", "Videos/2023/")
            done.append(video)
        else:
            print(video, "Extension not supported! Please provide a valid file, such as mp4 or mp3")

def visualize_wave(mp3_file_path):
    y, sr = librosa.load(mp3_file_path, sr=16000, duration=30)
    plt.figure(figsize=(7,3))
    librosa.display.waveshow(y, sr=sr)
    plt.title('Wave')
    plt.savefig('wave.png', format='png', transparent=True)
    plt.show()

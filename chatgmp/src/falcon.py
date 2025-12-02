import torch
from transformers import AutoTokenizer, FalconForCausalLM

tokenizer = AutoTokenizer.from_pretrained("Rocketknight1/falcon-rw-1b")
model = FalconForCausalLM.from_pretrained("Rocketknight1/falcon-rw-1b")

input = "Given the QUESTION, please provide an accurate answer based on the provided CONTEXT: QUESTION: What is the standard procedure for Maintenance in Good manufacturing practice (GMP)? CONTEXT:Yeah. This is the maintenance SOP, which tells about the general setup and how the calibration program has been organized. You can read that by yourself. And then I have you asked for it. So I'll show to you a real calibration record. Here it is. So this is an example of a calibration of a temperature sensor. You can see here what the temperature sensor where it is located and the type. You can see the instrument that we actually used to calibrate it. Here you can see the calibration data, how it went and it passed actually. So it's an instrument and intolerance was okay. So that's our, that's an example of a calibration record.        "
encoded_input = tokenizer([input], return_tensors='pt', max_length=1024, truncation=False)
        
output = model.generate(input_ids=encoded_input.input_ids,
                        attention_mask=encoded_input.attention_mask,
                        max_length=250,
                        num_beams=10,
                        num_return_sequences=3,
                        min_new_tokens=50
                        )
out = tokenizer.decode(output[0], skip_special_tokens=True)
print(out)
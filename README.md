# Ann-ReShade
A set of shaders made by me, intended for reshade but if you feel like using it elsewhere you have my permission.

#### Requirements
>[!IMPORTANT]
Cshade is required for blurring functionality

# DINN
DINN, is a set of shaders inspired by Return of the Obra Dinn. It features pixelation, black and white remapping, colour quantization and dithering. DINN - DIFF and DINN - GAUSS use edge detection to colour in edges to make the image more readable, DIFF uses a map of local colour derrivatives spread out using jump fill, while GAUSS uses the more computationally intensive difference of gaussians method to generate edges.
<p align="center"><img src="https://steamuserimages-a.akamaihd.net/ugc/2290707943337466585/98E4CE291A74F7B36A2769C0034107DF9271BC2B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false">
<i>A demo of DINN used on a screenshot of the movie master and commander. </i></p>

# Acknowledgements
Shoutout to the reshade discord community, ya'll helped a lot bit. 

Also special thanks to papadanku for letting me use their gaussian blurring implementation.

Blue noise map obtained from https://momentsingraphics.de/BlueNoise.html , good article also.

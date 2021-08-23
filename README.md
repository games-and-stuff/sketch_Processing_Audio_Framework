# sketch_Processing_Audio_Framework

Non-real time (Offline) Sound Analysis Framework for Processing

//  Non-real time Music Video & Sound Analysis Framework by Harcore Scm

//  If interested please check out my other work at hardcorescm.bandcamp.com

//  Based on offlineAnalysis.pde found at 

//  https://github.com/ddf/Minim/blob/master/examples/Analysis/offlineAnalysis/offlineAnalysis.pde

//  For more information about Minim and additional features, visit http://code.compartmental.net/minim/

//  This sketch enables non-real time (offline) analysis of an audio file to give 

//  FFT and Volume data for each frame of a sketch.  

//  For use when sketches are too slow/complex to run in real time at the desired frame rate, resolution etc

//  The sketch generates arrays of information at chosen video frames-per-second 

//  that can then be used to run the animation and save the individual frames

//  for later video creation in a video editor

//  For the LEFT and Right channels the sketch makes arrays of FFT and Volume directly 

//  from the soundfile. The CENTER channel data is an average of the LEFT and RIGHT

//  For MONO files = data will be identical in LEFT, RIGHT and CENTER data arrays

//  Generated data available for each animation frame:

//  Data Type          ¦  LEFT Channel  ¦   RIGHT Channel  ¦  CENTER Audio Channel

//  -------------------¦----------------¦------------------¦-------------------------

//  Audio Samples      ¦  samplesL      ¦   samplesR       ¦  SamplesC   = (left + right) * 0.5

//  FFT Array          ¦  spectraL      ¦   spectraR       ¦  spectraC

//  Volume Array       ¦  volumeL       ¦   volumeR        ¦  volumeC

//  RMS Volume Array   ¦  volumeLRMS    ¦   volumeRRMS     ¦  volumeCRMS

//  Max FFT Value      ¦  MaxFFTL       ¦   MaxFFTR        ¦  MaxFFTR 

//  Max Vol Value      ¦  MaxVolL       ¦   MaxVolR        ¦  MaxVolC

//  Max RMS Vol Value  ¦  MaxVolLRMS    ¦   MaxVolRRMS     ¦  MaxVolCRMS

//  Press "p" to start/stop animation

//  Use mouse wheel to step through one frame at a time 

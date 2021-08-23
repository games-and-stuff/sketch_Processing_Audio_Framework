//  Non-real time Music Video & Sound Analysis Framework by Harcore Scm
//  If interested please check out my other work at hardcorescm.bandcamp.com
//
//  Based on offlineAnalysis.pde found at 
//  https://github.com/ddf/Minim/blob/master/examples/Analysis/offlineAnalysis/offlineAnalysis.pde
//  For more information about Minim and additional features, visit http://code.compartmental.net/minim/
//
//  This sketch enables non-real time (offline) analysis of an audio file to give 
//  FFT and Volume data for each frame of a sketch.  
//  For use when sketches are too slow/complex to run in real time at the desired frame rate, resolution etc
// 
//  The sketch generates arrays of information at chosen video frames-per-second 
//  that can then be used to run the animation and save the individual frames
//  for later video creation in a video editor
//
//  For the LEFT and Right channels the sketch makes arrays of FFT and Volume directly 
//  from the soundfile. The CENTER channel data is an average of the LEFT and RIGHT
//
//  For MONO files = data will be identical in LEFT, RIGHT and CENTER data arrays
//
//  Generated data available for each animation frame:
//
//  Data Type          ¦  LEFT Channel  ¦   RIGHT Channel  ¦  CENTER Audio Channel
//  -------------------¦----------------¦------------------¦-------------------------
//  Audio Samples      ¦  samplesL      ¦   samplesR       ¦  SamplesC   = (left + right) * 0.5
//  FFT Array          ¦  spectraL      ¦   spectraR       ¦  spectraC
//  Volume Array       ¦  volumeL       ¦   volumeR        ¦  volumeC
//  RMS Volume Array   ¦  volumeLRMS    ¦   volumeRRMS     ¦  volumeCRMS
//  Max FFT Value      ¦  MaxFFTL       ¦   MaxFFTR        ¦  MaxFFTR 
//  Max Vol Value      ¦  MaxVolL       ¦   MaxVolR        ¦  MaxVolC
//  Max RMS Vol Value  ¦  MaxVolLRMS    ¦   MaxVolRRMS     ¦  MaxVolCRMS
//
//  Press "p" to start/stop animation
//  Use mouse wheel to step through one frame at a time 

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;

Minim minim;

float[][] spectraL, spectraR, spectraC;
float[][] samplesL, samplesR, samplesC;
float[] volumeL, volumeR, volumeC;
float[] volumeLRMS, volumeRRMS, volumeCRMS;
float MaxFFTL, MaxFFTR, MaxFFTC;
float MaxVolL, MaxVolR, MaxVolC;
float MaxVolLRMS, MaxVolRRMS, MaxVolCRMS;
float[] volumetemp;
float audioFPS;

//-----Variables to change-----!!!!!!!! 

   //-----The frames per second rate of the video you want to make
   int videoFPS = 60;

   //-----Size of FFT array MUST BE A POWER OF 2 - useable data points for the FFT is half the fftSize
   int fftSize = 1024;

   //----Audio Filename (assumed to be in the data folder of the sketch)
   //test file can be found here https://archive.org/download/20s-tests-44
   String filename = "20sTests44.wav";
   //String filename = "Your file name here.wav";

   //----Path to save frames of animation to - sub folder will be made using filename of audio
   String savepath = "D:/Renders/";

   //----Save the animation frames to file? true or false 
   //----the draw loop is always running - if true = will save frames even if playing is paused (false)
   //----when you are ready to render the animation set saveVid and playing to true and run sketch
   boolean saveVid = false;

   //----automatically step through the animation frames? true or false?
   boolean playing = false;

// the variable used to step through each frame of animation in the draw loop
int counter = 0;

//-----Global variables for your drawing
float leftHeight, rightHeight;
int spectraMap;

void setup()
  {
    minim = new Minim(this);
    analyzeUsingAudioSample();
    
//-----Sketch Drawing Setup Code Here
    size(1920, 1080);
    frameRate(videoFPS);
    
    leftHeight = height*0.33;
    rightHeight = height*0.67;
    spectraMap = (height/3)-70;

  }


void analyzeUsingAudioSample()
{ //load the sound file
  AudioSample audiofile = minim.loadSample(filename, 2048);
  
  //work out the number of audio-frames per video-frame (audio sample rate / video frames-per-second)
  audioFPS = audiofile.sampleRate()/videoFPS;
  
  //get left and right channels and put in loat arrays
  float[] leftChannel = audiofile.getChannel(AudioSample.LEFT);

  //detect if right channel exists (stereo file), use left if it doesn't (mono)
  float[] rightChannel;  
  try {
    rightChannel = audiofile.getChannel(AudioSample.RIGHT);
    }
    catch (IllegalArgumentException e) {
    rightChannel = audiofile.getChannel(AudioSample.LEFT);
  }

  //calculate center channel from left and right
  float[] centerChannel = new float[leftChannel.length];
  for(int i = 0; i < leftChannel.length; i++)
  {
  centerChannel[i] = (leftChannel[i] + rightChannel[i]) * 0.5;
  }
  
  //the useable data points for the FFT will be half the fftSize
  int fftHalf = fftSize/2;
    
  float[] fftSamples = new float[fftSize];
  FFT fft = new FFT( fftSize, audiofile.sampleRate() );
  
  //We analyze the samples in chunks. The chunk size is the number of audio-frames that occur for each video-frame. 
  //Total chunks is audio length / chunk size
  int totalChunks = int((leftChannel.length / audioFPS) + 1);
  
  // allocate the arrays that will hold all of the data for all of the chunks.
  // for FFT data - the second dimension is fftSize/2 because the spectrum size is always half the number of samples analyzed.
  spectraL = new float[totalChunks][fftHalf];
  spectraR = new float[totalChunks][fftHalf];
  spectraC = new float[totalChunks][fftHalf];
  
  samplesL = new float[totalChunks][fftSize];
  samplesR = new float[totalChunks][fftSize];
  samplesC = new float[totalChunks][fftSize];

  volumeL = new float[totalChunks];
  volumeR = new float[totalChunks];
  volumeC = new float[totalChunks];
  
  volumeLRMS = new float[totalChunks];
  volumeRRMS = new float[totalChunks];
  volumeCRMS = new float[totalChunks];

  volumetemp = new float[fftSize];

//-----Run through the audio file one frame of animation at a time, get fft and volume data for each channel

  for(int chunkIdx = 0; chunkIdx < totalChunks; ++chunkIdx)
  {
    //move the start position forwards by number of chunks of audio in one frame of animation
    int chunkStartIndex = round(chunkIdx * audioFPS);
        
    // the chunk size will always be fftSize, except for the 
    // last chunk, which will be however many samples are left in source
    int chunkSize = min( leftChannel.length - chunkStartIndex, fftSize );

//LEFT CHANNEL
    // copy first chunk into our analysis array
    System.arraycopy( leftChannel, // source of the copy
                  chunkStartIndex, // index to start in the source
                       fftSamples, // destination of the copy
                                0, // index to copy to
                         chunkSize // how many samples to copy
                                 );
      
    // if the chunk was smaller than the fftSize, we need to pad the analysis buffer with zeroes        
    if ( chunkSize < fftSize ){
    // we use a system call for this
    java.util.Arrays.fill( fftSamples, chunkSize, fftSamples.length - 1, 0.0 );
    }
    
    // now analyze this buffer
    fft.forward( fftSamples );
   
    // and copy the resulting spectrum into our spectra array
    for(int i = 0; i < fftHalf; ++i) { 
    spectraL[chunkIdx][i] = fft.getBand(i);    
    }

    //copy the samples into samples array
    for (int i = 0; i < fftSamples.length; i++){
    samplesL[chunkIdx][i] = fftSamples[i];
    }
    
    //volume at this video frame - based on max value of the fftsamples 
    for (int i = 0; i < fftSamples.length; i++){
    volumetemp[i] = abs(fftSamples[i]);
    }
    volumeL[chunkIdx] = max(volumetemp);
    
    //volume at this video frame - based on root mean square of all fftsamples
    float totalFFT = 0;
    for (int i = 0; i < fftSamples.length; i++){
    totalFFT += sq(fftSamples[i]);
    }
    totalFFT = totalFFT/fftSamples.length;
    volumeLRMS[chunkIdx] = sqrt(totalFFT);
    
//RIGHT CHANNEL
    // copy first chunk into our analysis array
    System.arraycopy( rightChannel, // source of the copy
                  chunkStartIndex,  // index to start in the source
                       fftSamples,  // destination of the copy
                                0,  // index to copy to
                         chunkSize  // how many samples to copy
                                 );
    
    // if the chunk was smaller than the fftSize, we need to pad the analysis buffer with zeroes  
    if ( chunkSize < fftSize ){
    java.util.Arrays.fill( fftSamples, chunkSize, fftSamples.length - 1, 0.0 );
    }
    
    // now analyze this buffer
    fft.forward( fftSamples );
    
    // and copy the resulting spectrum into our spectra array
    for(int i = 0; i < fftHalf; ++i)
    { 
     spectraR[chunkIdx][i] = fft.getBand(i);    
    }
    
    //copy the samples into samples array
    for (int i = 0; i < fftSamples.length; i++){
    samplesR[chunkIdx][i] = fftSamples[i];
    }

    //volume at this video frame - based on max value of the fftsamples 
    for (int i = 0; i < fftSamples.length; i++){
    volumetemp[i] = abs(fftSamples[i]);
    }
    volumeR[chunkIdx] = max(volumetemp);

    //volume at this video frame - based on root mean square of all fftsamples
    totalFFT = 0;
    for (int i = 0; i < fftSamples.length; i++){
    totalFFT += sq(fftSamples[i]);
    }
    totalFFT = totalFFT/fftSamples.length;
    volumeRRMS[chunkIdx] = sqrt(totalFFT);

//CENTER CHANNEL
    // copy first chunk into our analysis array
    System.arraycopy( centerChannel, // source of the copy
                   chunkStartIndex,  // index to start in the source
                        fftSamples,  // destination of the copy
                                 0,  // index to copy to
                          chunkSize  // how many samples to copy
                                  );
    
    // if the chunk was smaller than the fftSize, we need to pad the analysis buffer with zeroes  
    if ( chunkSize < fftSize ){
    java.util.Arrays.fill( fftSamples, chunkSize, fftSamples.length - 1, 0.0 );
    }
    
    // now analyze this buffer
    fft.forward( fftSamples );
    
    // and copy the resulting spectrum into our spectra array
    for(int i = 0; i < fftHalf; ++i)
    { 
     spectraC[chunkIdx][i] = fft.getBand(i);    
    }
    
    //copy the samples into samples array
    for (int i = 0; i < fftSamples.length; i++){
    samplesC[chunkIdx][i] = fftSamples[i];
    }

    //volume at this video frame - based on max value of the fftsamples 
    for (int i = 0; i < fftSamples.length; i++){
    volumetemp[i] = abs(fftSamples[i]);
    }
    volumeC[chunkIdx] = max(volumetemp);

    //volume at this video frame - based on root mean square of all fftsamples
    totalFFT = 0;
    for (int i = 0; i < fftSamples.length; i++){
    totalFFT += sq(fftSamples[i]);
    }
    totalFFT = totalFFT/fftSamples.length;
    volumeCRMS[chunkIdx] = sqrt(totalFFT);
                                 
//end of loop
}

//--don't need the audiofile anymore so close it
    audiofile.close();  
  
//------- Find the max values of the data  
    float[] MaxFFTTemp = new float[spectraL.length];
  
  //--Left Channel
    for(int i = 0; i < spectraL.length; ++i)
    {
      MaxFFTTemp[i] = max(spectraL[i]);
    }
    MaxFFTL = max(MaxFFTTemp);
    
  //--Right Channel    
    for(int i = 0; i < spectraR.length; ++i)
    {
      MaxFFTTemp[i] = max(spectraR[i]);
    }
    MaxFFTR = max(MaxFFTTemp);
    
  //--center Channel    
    for(int i = 0; i < spectraC.length; ++i)
    {
      MaxFFTTemp[i] = max(spectraC[i]);
    }
    MaxFFTC = max(MaxFFTTemp);
  
  MaxVolL = max(volumeL);
  MaxVolR = max(volumeR);
  MaxVolC = max(volumeC);
  
  MaxVolLRMS = max(volumeLRMS);
  MaxVolRRMS = max(volumeRRMS);
  MaxVolCRMS = max(volumeCRMS);
 
}

void draw(){
   background(0);
   stroke(255);
   strokeWeight(3);
   fill(255,255,255);
   
   textSize(32);
   text("Left", 10, 40);
   text("Right", 10, leftHeight+40);
   text("Center", 10, rightHeight+40);

   line(0,height*0.33,width,height*0.33);
   line(0,height*0.67,width,height*0.67);

strokeWeight(1);

   fill(255,50,50);
   stroke(255,50,50);
   text("Samples/Waveform", 10, leftHeight-10);
   text("Samples/Waveform", 10, rightHeight-10);
   text("Samples/Waveform", 10, height-10);
   
      for(int i = 0; i < samplesL[counter].length-1; ++i )
   {
       line(1+i, leftHeight-60, 1+i, leftHeight-60+samplesL[counter][i]*25); 
       line(1+i, rightHeight-60, 1+i, rightHeight-60+samplesR[counter][i]*25); 
       line(1+i, height-60, 1+i, height-60+samplesC[counter][i]*25);               
   }
   
   fill(100,100,255);
   stroke(100,100,255);
   text("Spectra", fftSize + 10, leftHeight-10);
   text("Spectra", fftSize + 10, rightHeight-10);
   text("Spectra", fftSize + 10, height-10);  
   
   for(int i = 0; i < spectraL[counter].length-1; ++i )
   {
       line(fftSize + 10+i, leftHeight-60, fftSize + 10+i, leftHeight - 60 - map(spectraL[counter][i],0,MaxFFTL,0,spectraMap)); 
       line(fftSize + 10+i, rightHeight-60, fftSize + 10+i, rightHeight-60- map(spectraR[counter][i],0,MaxFFTR,0,spectraMap)); 
       line(fftSize + 10+i, height-60, fftSize + 10+i, height-60- map(spectraC[counter][i],0,MaxFFTC, 0,spectraMap));               
   }
   
   fill(255,100,255);
   stroke(255,100,255);
   text("Vol ABS", fftSize + fftSize/2 + 50, leftHeight-10);
   text("Vol ABS", fftSize + fftSize/2 + 50, rightHeight-10);
   text("Vol ABS", fftSize + fftSize/2 + 50, height-10);

   noFill();
   ellipse(fftSize + fftSize/2 + 90,leftHeight-100,MaxVolL*100,MaxVolL*100);
   ellipse(fftSize + fftSize/2 + 90,rightHeight-100,MaxVolR*100,MaxVolR*100);
   ellipse(fftSize + fftSize/2 + 90,height-100,MaxVolC*100,MaxVolC*100);

   fill(255,100,255);
   ellipse(fftSize + fftSize/2 + 90,leftHeight-100,volumeL[counter]*100,volumeL[counter]*100);
   ellipse(fftSize + fftSize/2 + 90,rightHeight-100,volumeR[counter]*100,volumeR[counter]*100);
   ellipse(fftSize + fftSize/2 + 90,height-100,volumeC[counter]*100,volumeC[counter]*100);

   fill(100,255,100);
   stroke(100,255,100);
   text("Vol RMS", fftSize + fftSize/2 + 190, leftHeight-10);
   text("Vol RMS", fftSize + fftSize/2 + 190, rightHeight-10);
   text("Vol RMS", fftSize + fftSize/2 + 190, height-10);
   
   noFill();
   ellipse(fftSize + fftSize/2 + 240,leftHeight-100,MaxVolLRMS*100,MaxVolLRMS*100);
   ellipse(fftSize + fftSize/2 + 240,rightHeight-100,MaxVolRRMS*100,MaxVolRRMS*100);
   ellipse(fftSize + fftSize/2 + 240,height-100,MaxVolCRMS*100,MaxVolCRMS*100);

   fill(100,255,100);
   ellipse(fftSize + fftSize/2 + 240,leftHeight-100,volumeLRMS[counter]*100,volumeLRMS[counter]*100);
   ellipse(fftSize + fftSize/2 + 240,rightHeight-100,volumeRRMS[counter]*100,volumeRRMS[counter]*100);
   ellipse(fftSize + fftSize/2 + 240,height-100,volumeCRMS[counter]*100,volumeCRMS[counter]*100);
   

  //save the current frame
  if(saveVid){
  saveFrame(savepath+filename+"/frame-######.png"); 
  }
 
  //if currently playing move the counter to next frame
  if (playing){
  counter +=1;
  println("Current Frame: " + counter + " / " + samplesL.length);
  }
  
  //check if end of file reached
  if (counter > spectraL.length-1) {                      
  println("Finished");
  exit();
  }
  
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e>0){counter --;}
  if (e<0){counter ++;}
  if(counter<0){counter=0;}
  if(counter>samplesL.length){counter=samplesL.length;}
  println("Current Frame: " + counter + " / " + samplesL.length);
}
  
  void keyPressed() {
    if (key == 'p') {playing = ! playing;}
}

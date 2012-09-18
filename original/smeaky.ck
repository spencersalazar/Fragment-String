
//-----------------------------------------------------------------------------
// name: smeaky
// desc: live input granular+ resynthesizer
// 
// author: Spencer Salazar, 2012
//
//-----------------------------------------------------------------------------

/* based on: */
//-----------------------------------------------------------------------------
// name: LiSa
// desc: Live sampling utilities for ChucK
//
// author: Dan Trueman, 2007
//
// to run (in command line chuck):
//     %> chuck LiSa_readme.ck
//-----------------------------------------------------------------------------

/*

These three example files demonstrate a couple ways to approach granular sampling
with ChucK and LiSa. All are modeled after the munger~ from PeRColate. One of the
cool things about doing this in ChucK is that there is a lot more ready flexibility
in designing grain playback patterns; rolling one's own idiosyncratic munger is 
a lot easier. 

Example 2 (below) demonstrates the rotating buffer approach used in the munger~
see after the code for an explanation of this approach. presumably someone 
smarter than me will dream up a more elegant technique. 

*/



//use three buffers
LiSa l[3];
5::second => dur bufferlen;
0 => int recbuf;
2 => int playbuf;

adc => Dyno inDyno => Gain samplerInput;
inDyno.limit();
0.001 => inDyno.thresh;
0.001 => inDyno.slopeAbove;

Gain samplerOutput => BPF filter => Dyno limiter => dac;

limiter.limit();
20 => limiter.gain;

//-1 => filter.op;
10 => filter.gain;
440 => filter.freq;
1 => filter.Q;

//LiSa params
for(0=>int i; i<3; i++) {
    
    l[i].duration(bufferlen);
    l[i].maxVoices(30);
    l[i].clear();
    l[i].gain(0.1);
    l[i].feedback(0.5);
    l[i].recRamp(20::ms);
    l[i].record(0);
    
    samplerInput => l[i] => Mix2 mix => Gain g => samplerOutput;
    1 => mix.pan;
    10 => g.gain;
}

l[recbuf].record(1);

//create grains, rotate record and play bufs as needed
//shouldn't click as long as the grainlen < bufferlen
while(true) {
    
    now + bufferlen => time later;
    
    //toss some grains
    while (now<later) {
        
        1 => float newrate;
        Std.rand2f(250, 600) * 1::ms => dur newdur;
        
        spork ~ getgrain(playbuf, newdur, 20::ms, 20::ms, newrate);
        
        10::ms => now;
    }
    
    //rotate the record and playbufs
    l[recbuf++].record(0);
    if(recbuf == 3) 0 => recbuf;
    l[recbuf].record(1);
    
    playbuf++;
    if(playbuf == 3) 0 => playbuf;
    
}


fun void getgrain(int which, dur grainlen, dur rampup, dur rampdown, float rate)
{
    l[which].getVoice() => int newvoice;
    //<<<newvoice>>>;
    
    if(newvoice > -1) {
        l[which].rate(newvoice, rate);
        l[which].playPos(newvoice, Std.rand2f(0., 1.) * bufferlen);
        l[which].rampUp(newvoice, rampup);
        (grainlen - (rampup + rampdown)) => now;
        l[which].rampDown(newvoice, rampdown);
        rampdown => now;
    }
    
}

/*

Rotating Buffer Explanation (from the munger~ source code). 

the munger~ (and scrubber~) use a rotating three-buffer scheme for creating clickless grains.  
basically, you don't want to be recording new data anywhere in the buffer where a grain might 
be playing. so, we divide the buffer into three equal parts (B1, B2, B3). at the outset, let's say:

B1 = the recording buffer part (RB)
B2 = a part where nothing is happening (QB, for Quiet Buffer)
B3 = a part where grains are playing from (PB)

let's say each part is N samples long. after we have recorded N sample into B1, we rotate
the functionality, so now:

B1 = PB
B2 = RB
B3 = QB

why?

as long as the grains are guaranteed to be no longer than N samples (adjusted for playback rate) we
are assured that none of them will have clicks due to recording discontinuities. we need the Quiet Buffer
because when the rotation happens, there may still be grains playing in what was the PB and is now the QB.

*/


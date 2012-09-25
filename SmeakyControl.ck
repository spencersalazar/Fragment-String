

class HandCtlFilter extends CtlOnePole
{
    HandCtlFilter @ other;
    
    fun void onUpdate()
    {
        if(other != null)
            Math.sqrt(other.last() * this.last()) => gfx.level;
        else 
            this.last() => gfx.level;
    }
}

class Hand
{
    fun void processX(float x)
    {
    }
    
    fun void processY(float y)
    {
    }
    
    fun void processZ(float z)
    {
    }
}

class RightHand extends Hand
{
    Gain inlet => SmeakySynth sm => FilterStack fs => Gain master => Gain outlet;
    HandCtlFilter ctlFilter;
    0.9 => ctlFilter.a;
    
    0 => int handNo;
    
    sm.init(15::second);
    1 => sm.pause;
    
    fs.init(12);
    
    32 => Std.mtof => fs.freq;
    50 => fs.Q;
    
    0.95 => float RECORD_THRESHOLD;
    0.90 => float PLAY_THRESHOLD;
    
    for(int j; j < fs.numFilters(); j++)
    {
        // triangle wave
        if(j%2 == 0) // even harmonic
            fs.gainAt(j, 0);
        else // odd harmonic
            fs.gainAt(j, Math.pow(-1,j/2)/(j*j));
    }
    
    fun void processX(float x)
    {
        if(x < 0)
        {
            Math.pow(2,x) => fs.Q;
            1 => fs.gain;
        }
        else
        {
            Math.pow(2,x*6) => fs.Q;
            fs.Q()*2 => Std2.db2lin => fs.gain;
        }
    }
    
    fun void processY(float y)
    {
        (1+y)/2.0 => sm.playbackPosition;
    }
    
    fun void processZ(float z)
    {
        if(z > RECORD_THRESHOLD)
        {
            sm.recordMode();
            gfx.mode(0, handNo);
        }
        else if(z < PLAY_THRESHOLD)
        {
            sm.playMode();
            gfx.mode(1, handNo);
        }
        
        20+((1+z)/2.0)*-40 => Std2.db2lin => master.gain;
        Std2.clamp(1-master.gain(), 0, 1) => ctlFilter.tick;
    }
}

class LeftHand extends Hand
{
    SmeakySynth @ sm;
    
    float lastX;
    float lastY;
    float lastZ;
    
    fun void processX(float x)
    {
    }
    
    fun void processY(float y)
    {
    }
    
    fun void processZ(float z)
    {
        z-lastZ => float diff;
        Math.fabs(z-lastZ) => float absdiff;
        diff/absdiff => float sign;
        
        30 => int divisions;
        
        if(absdiff < 0.1)
            0 => sm.rateDeviation;
        else
        {
            Math.floor(absdiff*divisions)/divisions => absdiff;
            Math.pow(2,(absdiff-0.1)*sign*2*-1)-1 => sm.rateDeviation;
        }
        
    }
}

Hand hand[2];
RightHand left @=> hand[0];
RightHand right @=> hand[1];
0 => left.handNo;
1 => right.handNo;

adc => Dyno inDyno => Gain samplerInput;
inDyno.limit();
0.0001 => inDyno.thresh;
0.001 => inDyno.slopeAbove;
500::ms => inDyno.releaseTime;
5::ms => inDyno.attackTime;
0.1 => inDyno.gain;

Gain samplerOutput => BPF filter => Dyno limiter => dac;

1.0/hand.cap() => samplerOutput.gain;

limiter.limit();
//40 => limiter.gain;
1000 => limiter.gain;

-1 => filter.op;
1 => filter.gain;
440 => filter.freq;
1 => filter.Q;

samplerInput => left.inlet;
left.outlet => samplerOutput;
samplerInput => right.inlet;
right.outlet => samplerOutput;

1.0 => left.sm.rate;
1.0 => right.sm.rate;

Hid gt;
HidMsg msg;
gt.openJoystick(0);

while(true)
{
    gt => now;
    while(gt.recv(msg))
    {
        if(msg.type == Hid.AXIS_MOTION)
        {
            if(msg.which%3 == 0)
            {
                hand[Math.floor(msg.which/3.0)$int].processX(msg.axisPosition);
            }
            if(msg.which%3 == 1)
            {
                hand[Math.floor(msg.which/3.0)$int].processY(msg.axisPosition);
            }
            if(msg.which%3 == 2)
            {
                hand[Math.floor(msg.which/3.0)$int].processZ(msg.axisPosition);
            }
        }
    }
}


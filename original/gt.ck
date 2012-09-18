
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

class Hand extends Chubgraph
{
    inlet => Smeaky sm => FilterStack fs => Gain master => outlet;
    HandCtlFilter ctlFilter;
    0.9 => ctlFilter.a;
    
    0 => int handNo;
    
    sm.init(15::second);
    1 => sm.pause;
    
    fs.init(12);
    
    80 => Std.mtof => fs.freq;
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

Hand hand[2];
0 => hand[0].handNo;
1 => hand[1].handNo;
hand[0].ctlFilter @=> hand[1].ctlFilter.other;
hand[1].ctlFilter @=> hand[0].ctlFilter.other;

adc => Dyno inDyno => Gain samplerInput;
inDyno.limit();
0.001 => inDyno.thresh;
0.001 => inDyno.slopeAbove;
500::ms => inDyno.releaseTime;
5::ms => inDyno.attackTime;
0.1 => inDyno.gain;

Gain samplerOutput => BPF filter => Dyno limiter => dac;

1.0/hand.cap() => samplerOutput.gain;

limiter.limit();
40 => limiter.gain;

-1 => filter.op;
1 => filter.gain;
440 => filter.freq;
1 => filter.Q;

for(int i; i < hand.cap(); i++)
{
    samplerInput => hand[i] => samplerOutput;
}

1.0 => hand[0].sm.rate;
3.0/4.0 => hand[1].sm.rate;

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



dac.channels() => int NUM_CHANNELS;

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

class Feedback extends Chubgraph
{
    inlet => Gain direct => outlet;
    inlet => Delay delay => Gain feedback => outlet;
    feedback => delay;
}

class Hand extends Chubgraph
{
    fun void processX(float x) { }
    fun void processY(float y) { }
    fun void processZ(float z) { }
    fun void buttonDown() { }
    fun void buttonUp() { }
}

class RightHand extends Hand
{
    FilterStack fs;
    inlet => SmeakySynth sm => Gain direct => Gain master => outlet;
    
    sm => Gain beastModeInput;
    Feedback fb[NUM_CHANNELS];
    Gain beastMode[NUM_CHANNELS];
    Gain beastModePre[NUM_CHANNELS];
    0 => int inBeastMode;
    0 => beastModeInput.gain;
    
    for(int j; j < NUM_CHANNELS; j++)
    {
        beastModeInput => beastModePre[j] => fb[j] => beastMode[j];
        2::second => fb[j].delay.max;
        50::ms => fb[j].delay.delay;
        0.89/2.0 => fb[j].feedback.gain;
        0 => fb[j].direct.gain;
        fb[j].delay => fb[(j+3)%NUM_CHANNELS].feedback;
    } 
    
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
        x => float diff;
        Math.fabs(x) => float absdiff;
        diff/absdiff*(handNo*2-1) => float sign;
        
        30 => int divisions;
        
        0.2 => float deadzone;
        
        if(absdiff < deadzone)
            1 => sm.rate;
        else
        {
            Math.floor(absdiff*divisions)/divisions => absdiff;
            Math.pow(2,(absdiff-deadzone)*sign*2*-1) => sm.rate;
        }
        
        for(int i; i < NUM_CHANNELS; i++)
        {
            Std2.clamp(1+absdiff*3.0 - Math.floor(i/2.0), 0, 1) => beastMode[i].gain;
            beastMode[i].gain()*500::ms + 25::ms => fb[i].delay.delay;
        }
        
        //if(x < 0)
        //{
        //    Math.pow(2,x) => fs.Q;
        //    1 => fs.gain;
        //}
        //else
        //{
        //    Math.pow(2,x*6) => fs.Q;
        //    fs.Q()*2 => Std2.db2lin => fs.gain;
        //}
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
        for(int i; i < NUM_CHANNELS; i++)
        {
            master.gain() => beastModePre[i].gain;
        }
        Std2.clamp(1-master.gain(), 0, 1) => ctlFilter.tick;
    }
    
    fun void buttonDown()
    {
        chout <= "beast mode\n";
        1 => inBeastMode;
        1 => beastModeInput.gain;
    }
    
    fun void buttonUp()
    {
        chout <= "normal mode\n";
        0 => inBeastMode;
        0 => beastModeInput.gain;
    }
}


Hand hand[2];
RightHand left @=> hand[0];
RightHand right @=> hand[1];
0 => left.handNo;
1 => right.handNo;

adc => Dyno inDyno => Gain samplerInput;
inDyno.limit();
0.001 => inDyno.thresh;
0.001 => inDyno.slopeAbove;
1000::ms => inDyno.releaseTime;
15::ms => inDyno.attackTime;
0.1 => inDyno.gain;

//Gain samplerOutput => Dyno limiter => dac;
Gain samplerOutput;

1.0/hand.cap() => samplerOutput.gain;

//limiter.limit();
//40 => limiter.gain;
//1000 => limiter.gain;

samplerInput => left => samplerOutput;
samplerInput => right => samplerOutput;
Dyno limiterMC[NUM_CHANNELS];
for(int i; i < NUM_CHANNELS; i++)
{
    NRev reverb => limiterMC[i] => dac.chan(i);
    0.1 => reverb.mix;
    limiterMC[i].limit();
    100 => limiterMC[i].gain;
    left.beastMode[i] => reverb;
    right.beastMode[i] => reverb;
    samplerOutput => limiterMC[i];
}

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
        else if(msg.type == Hid.BUTTON_DOWN)
        {
            hand[0].buttonDown();
            hand[1].buttonDown();
        }
        else if(msg.type == Hid.BUTTON_UP)
        {
            hand[0].buttonUp();
            hand[1].buttonUp();
        }
    }
}



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
    inlet => DelayA delay => Gain feedback => outlet;
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
    inlet => SmeakySynth sm => BRF sweeper1 => Gain direct => Gain master;
    
    sm => Gain beastModeInput;
    Feedback fb[NUM_CHANNELS];
    Gain beastMode[NUM_CHANNELS];
    Gain beastModePre[NUM_CHANNELS];
    Gain multiOut[NUM_CHANNELS];
    0 => int inBeastMode;
    0 => beastModeInput.gain;
    
    10 => sweeper1.Q;
    
    for(int j; j < NUM_CHANNELS; j++)
    {
        beastModeInput => beastModePre[j] => fb[j] => beastMode[j];
        2::second => fb[j].delay.max;
        50::ms => fb[j].delay.delay;
        0.89/2.0 => fb[j].feedback.gain;
        0 => fb[j].direct.gain;
        fb[j].delay => fb[(j+2)%NUM_CHANNELS].feedback;
        
        master => multiOut[j];
    } 
    
    HandCtlFilter ctlFilter;
    0.9 => ctlFilter.a;
    
    0 => int handNo;
    
    sm.init(10::second);
    1 => sm.pause;
    
    0.95 => float RECORD_THRESHOLD;
    0.90 => float PLAY_THRESHOLD;
    
    spork ~ go();
    
    fun void processX(float x)
    {
        x => float diff;
        Math.fabs(x) => float absdiff;
        diff/absdiff*(handNo*2-1) => float sign;
        
        23 => int divisions;
        
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
            Std2.clamp(1+absdiff*3.0 - Math.floor(i/2.0), 0, 1) => multiOut[i].gain;
            beastMode[i].gain()*beastMode[i].gain()*500::ms + 25::ms => fb[i].delay.delay;
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
    
    fun void go()
    {
        20::ms => dur kr;
        samp/second => float SRATE;
        
        while(true)
        {
            700+500*Math.sin(2*Math.PI*(kr/samp)/SRATE*2) => sweeper1.freq;
            kr => now;
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
0.001 => inDyno.thresh;
0.001 => inDyno.slopeAbove;
1000::ms => inDyno.releaseTime;
15::ms => inDyno.attackTime;
0.1 => inDyno.gain;

Gain samplerOutput;

1.0/hand.cap() => samplerOutput.gain;

samplerInput => left => samplerOutput;
samplerInput => right => samplerOutput;
Dyno limiterMC[NUM_CHANNELS];
for(int i; i < NUM_CHANNELS; i++)
{
    NRev reverb => limiterMC[i] => dac.chan(i);
    0.1 => reverb.mix;
    limiterMC[i].limit();
    10 => limiterMC[i].gain;
    left.beastMode[i] => reverb;
    right.beastMode[i] => reverb;
    
    left.multiOut[i] => limiterMC[i];
    right.multiOut[i] => limiterMC[i];
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


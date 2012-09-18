
Smeaky sm[2];
FilterStack fs[2];

adc => Dyno inDyno => Gain samplerInput;
inDyno.limit();
0.01 => inDyno.thresh;
0.001 => inDyno.slopeAbove;
500::ms => inDyno.releaseTime;
5::ms => inDyno.attackTime;
0.1 => inDyno.gain;

Gain samplerOutput => BPF filter => Dyno limiter => dac;

1.0/sm.cap() => samplerOutput.gain;

limiter.limit();
20 => limiter.gain;

-1 => filter.op;
1 => filter.gain;
440 => filter.freq;
1 => filter.Q;

for(int i; i < sm.cap(); i++)
{
    samplerInput => sm[i] => fs[i] => samplerOutput;
    sm[i].init(15::second);
    
    fs[i].init(12);
    
    72 => Std.mtof => fs[i].freq;
    50 => fs[i].Q;
    
    for(int j; j < fs[i].numFilters(); j++)
    {
        // triangle wave
        if(j%2 == 0) // even harmonic
            fs[i].gainAt(j, 0);
        else // odd harmonic
            fs[i].gainAt(j, Math.pow(-1,j/2)/(j*j));
    }
}

1.0 => sm[0].rate;
3.0/4.0 => sm[1].rate;

Hid kb;
HidMsg msg;
kb.openKeyboard(0);

while(true)
{
    kb => now;
    while(kb.recv(msg))
    {
        if(msg.type == Hid.BUTTON_DOWN)
        {
            if(msg.ascii == 81) // q
            {
                for(int i; i < sm.cap(); i++)
                    sm[i].recordMode();
            }
            else if(msg.ascii == 80) // p
            {
                for(int i; i < sm.cap(); i++)
                    sm[i].playMode();
            }
            else if(msg.ascii == 32) // space
            {
                for(int i; i < sm.cap(); i++)
                {
                    1-sm[i].pause => sm[i].pause;
                    if(sm[i].pause) <<< "pause", "" >>>;
                    else <<< "unpause", "" >>>;
                }
            }
        }
    }
}

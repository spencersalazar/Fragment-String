
public class Smeaky extends Chubgraph
{
    LiSa record;
    LiSa play;
    
    dur bufferlen;
    dur recordDuration;
    dur playbackPos;
    0 => int mode; // 0 => record, 1 => play
    
    1 => float m_rate;
    0 => int pause;
    
    50 => int MAX_VOICES;
    
    /*** public API ***/
    
    fun void init(dur _bufferlen)
    {
        _bufferlen => bufferlen;
        bufferlen => record.duration;
        bufferlen => play.duration;
        
        record.maxVoices(MAX_VOICES);
        record.clear();
        record.gain(0.1);
        record.feedback(0.0);
        record.recRamp(20::ms);
        record.record(0);

        play.maxVoices(MAX_VOICES);
        play.clear();
        play.gain(0.1);
        play.feedback(0.0);
        play.recRamp(20::ms);
        play.record(0);
        
        Mix2 mix => Gain g => outlet;
        1 => mix.pan;
        10 => g.gain;

        inlet => record => mix;
        inlet => play => mix;
        
        spork ~ go();
    }
    
    fun void recordMode()
    {
        0 => mode;
    }
    
    fun void playMode()
    {
        1 => mode;
    }
    
    fun float rate(float r)
    {
        r => m_rate;
        return m_rate;
    }
    
    fun float rate()
    {
        return m_rate;
    }
    
    fun float playbackPosition(float p)
    {
        if(p >= 0 && p <= 1)
        {
            p*recordDuration => playbackPos;
        }
        
        return playbackPos/recordDuration;
    }
    
    
    /*** private internals ***/
    
    fun void go()
    {
        -1 => int loopMode; // internal copy of mode; only updated on loop iteration
        
        10::ms => dur kr;
        
        time recordStart;
        time playStart;
        
        while(true)
        {
            if(loopMode != mode)
            {
                mode => int newMode;
                
                if(newMode == 0) // record
                {
                    <<< "record mode", "" >>>;
                    0::second => record.recPos;
                    1 => record.record;
                    //1 => record.loopRec;
                    
                    now => recordStart;
                }
                else if(newMode == 1)
                {
                    <<< "play mode", "" >>>;
                    // stop recording
                    0 => record.record;
                    
                    // swap buffers
                    play @=> LiSa @ tmp;
                    record @=> play;
                    tmp @=> record;
                    
                    now - recordStart => recordDuration;
                    if(recordDuration > bufferlen)
                        bufferlen => recordDuration;
                    now => playStart;
                }
                
                newMode => loopMode;
            }
            
            if(loopMode == 1) // play
            {
                spork ~ grain(play, Std.rand2f(250, 600)::ms, 10::ms, 10::ms, m_rate, playbackPos);
                
                if(!pause)
                {
                    kr +=> playbackPos;
                    while(playbackPos > recordDuration)
                        recordDuration -=> playbackPos;
                }
            }
            
            kr => now;
        }
    }
    
    fun void grain(LiSa @ l, dur grainlen, dur rampup, dur rampdown, float rate, dur where)
    {
        //l.duration() => dur bufferlen;
        l.getVoice() => int newvoice;
        //<<<newvoice>>>;
        
        if(newvoice > -1)
        {
            l.rate(newvoice, rate);
            l.playPos(newvoice, where + Gaussian.generate()*100::ms);
            l.rampUp(newvoice, rampup);
            (grainlen - (rampup + rampdown)) => now;
            l.rampDown(newvoice, rampdown);
            rampdown => now;
        }
        
    }
}

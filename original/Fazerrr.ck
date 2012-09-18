
public class Fazerrr extends Chubgraph
{
    1 => int NUM_CHANNELS;
    
    SinOsc m[NUM_CHANNELS];
    SawOsc c[NUM_CHANNELS];
    LPF f[NUM_CHANNELS];
    Envelope env[NUM_CHANNELS];
    
    0 => float noise_factor;
    1 => float filter_freq_factor;
    
    1 => float _gain;
    1 => float Q;
    
    0 => int doStop;
    0 => int rampingDownGain;
    0 => int rampingDownFFF;
    0 => int rampingDownQ;
    
    for(0 => int i; i < NUM_CHANNELS; i++)
    {
        m[i] => c[i] => f[i] => env[i] => outlet;
        2 => c[i].sync;
        220 => c[i].freq;
        0.5 => c[i].gain;
        
        100 => m[i].gain;
        c[i].freq() * 0.5 => m[i].freq;
        
        100::ms => env[i].duration;
        
        Math.min(c[i].freq()*filter_freq_factor, second/samp/2) => f[i].freq;
        1 => f[i].Q;
    }
    
    fun void sound()
    {
        0 => doStop;
        
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            1 => env[i].keyOn;
        }
        
        while(!doStop)
        {
            for(0 => int i; i < NUM_CHANNELS; i++)
            {
                0 => float noise;
                if(noise_factor > 0)
                    Std.rand2f(-noise_factor, noise_factor) => noise;
                10000 * Math.sin((0.5-(i*0.05)+noise)*(now/second)) => m[i].gain;
                //10000 * Math.sin((0.5+i*0.5)*0.5*(now/second)) => m[i].gain;
                //c[i].freq() * (2+Math.cos((1+(i*0.2))*(now/second))) => m[i].freq;
            }
            
            20::ms => now;
        }
        
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            1 => env[i].keyOff;
        }
    }
    
    fun void stop()
    {
        1 => doStop;
    }
    
    fun void setFreq(float freq)
    {
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            freq => c[i].freq;
            c[i].freq() * 0.5 => m[i].freq;
            Math.min(c[i].freq()*filter_freq_factor, second/samp/2) => f[i].freq;
        }
    }
    
    fun void setGain(float g)
    {
        g => _gain;
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            0.2 * _gain => c[i].gain;
        }
    }
    
    fun void setFilterQ(float _Q)
    {
        _Q => Q;
        
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            Q => f[i].Q;
        }
    }
    
    fun void setFilterFreqFactor(float factor)
    {
        factor => filter_freq_factor;
        for(0 => int i; i < NUM_CHANNELS; i++)
        {
            Math.min(c[i].freq()*filter_freq_factor, second/samp/2) => f[i].freq;
        }
    }
    
    fun void rampUpGain(dur d, float gain_inc, float gain_max)
    {
        while(_gain < gain_max && !rampingDownGain)
        {
            setGain(Math.min(_gain+gain_inc, gain_max));
            
            d => now;
        }
    }
    
    fun void rampUpFFF(dur d, float fff_inc, float fff_max)
    {
        while(filter_freq_factor < fff_max && !rampingDownFFF)
        {
            setFilterFreqFactor(Math.min(filter_freq_factor+fff_inc, fff_max));
            
            d => now;
        }
    }
    
    fun void rampUpQ(dur d, float q_inc, float q_max)
    {
        while(Q < q_max && !rampingDownQ)
        {
            setFilterQ(Math.min(Q+q_inc, q_max));
            
            d => now;
        }
    }
    
    fun void rampDownGain(dur d, float gain_inc, float gain_min)
    {
        1 => rampingDownGain;
        while(_gain > gain_min)
        {
            setGain(Math.max(_gain-gain_inc, gain_min));
            
            d => now;
        }
        0 => rampingDownGain;
    }
    
    fun void rampDownFFF(dur d, float fff_inc, float fff_min)
    {
        1 => rampingDownFFF;
        while(filter_freq_factor > fff_min)
        {
            setFilterFreqFactor(Math.max(filter_freq_factor/(1+fff_inc), fff_min));
            
            d => now;
        }
        0 => rampingDownFFF;
    }
    
    fun void rampDownQ(dur d, float q_inc, float q_min)
    {
        1 => rampingDownQ;
        while(Q > q_min)
        {
            setFilterQ(Math.max(Q-q_inc, q_min));
            
            d => now;
        }
        0 => rampingDownQ;
    }
}



// really really bad cross synthesizer...

public class XSynth extends Chubgraph
{
    // our patch
    inlet => FFT X => blackhole;
    Gain m_synth => FFT Y => blackhole;
    // synthesis
    IFFT ifft => outlet;
    
    // set FFT size
    1024 => X.size => Y.size => int FFT_SIZE;
    // desired hop size
    FFT_SIZE / 4 => int HOP_SIZE;
    // set window and window size
    Windowing.hann(512) => X.window;
    Windowing.hann(512) => Y.window;
    Windowing.hann(512) => ifft.window;
    
    fun UGen synth()
    {
        return m_synth;
    }
    
    spork ~ go();
    
    fun void go()
    {
        // use this to hold contents
        complex Z[FFT_SIZE/2];
        
        // control loop
        while( true )
        {
            // take fft
            X.upchuck();
            Y.upchuck();
            
            // multiply
            for( int i; i < X.size()/2; i++ )
                (Y.cval(i)$polar).mag * X.cval(i) => Z[i];
            
            // take ifft
            //ifft.transform( Xspectrum );
            ifft.transform( Z );
            
            // advance time
            HOP_SIZE::samp => now;
        }
    }
}

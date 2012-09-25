// really really bad cross synthesizer...

// our patch
adc.chan(0) => FFT X => blackhole;
Noise n => FFT Y => blackhole;
// synthesis
IFFT ifft => dac;

// set FFT size
1024 => X.size => Y.size => int FFT_SIZE;
// desired hop size
FFT_SIZE / 4 => int HOP_SIZE;
// set window and window size
Windowing.hann(512) => X.window;
Windowing.hann(512) => Y.window;
Windowing.hann(512) => ifft.window;
// use this to hold contents
complex Xspectrum[FFT_SIZE/2];
complex Yspectrum[FFT_SIZE/2];
complex Z[FFT_SIZE/2];

// control loop
while( true )
{
    // take fft
    X.upchuck();
    Y.upchuck();
    
    X.spectrum( Xspectrum );
    Y.spectrum( Yspectrum );
    
    // multiply
    for( int i; i < X.size()/2; i++ )
        Math.sqrt((Y.cval(i)$polar).mag) * X.cval(i) => Z[i];
    
    // take ifft
    //ifft.transform( Xspectrum );
    ifft.transform( Z );
    
    // advance time
    HOP_SIZE::samp => now;
}


SerialIO.list() @=> string list[];

for(int i; i < list.cap(); i++)
{
    chout <= i <= ": " <= list[i] <= IO.newline();
}

0 => int device;
if(me.args()) me.arg(0) => Std.atoi => device;

SerialIO cereal;
cereal.open(device, SerialIO.B9600, SerialIO.BINARY);

while(true)
{
    cereal.onByte() => now;
    cereal.getByte() => int byte;
    if(byte == 255)
        break;
}

<<< "got sentinal byte", "" >>>;

SinOsc s => dac;
1 => s.gain;

while(true)
{
    cereal.onByte() => now;
    cereal.getByte() => int byte1;
    if(byte1 == 255) continue;
    
    cereal.onByte() => now;
    cereal.getByte() => int byte2;
    if(byte2 == 255) continue;
    
    cereal.onByte() => now;
    cereal.getByte() => int byte3;
    if(byte3 == 255) continue;
    
    cereal.onByte() => now;
    cereal.getByte() => int byte4;
    
    byte1 => Std.mtof => s.freq;
    byte3 => s.gain;
}


public class Panel
{
    float _knob1;
    float _knob2;
    int _sw1;
    
    fun void open(int device)
    {
        spork ~ go(device);
    }
    
    fun void go(int device)
    {
        SerialIO cereal;
        cereal.open(device, SerialIO.B9600, SerialIO.ASCII);
        
        while(true)
        {
            cereal.onLine() => now;
            cereal.getLine() => string line;
            if(line != null)
            {
                string matches[0];
                RegEx.match("([0-9]+),([0-9]+),([0-9]+)", line, matches);
                if(matches.size() == 4)
                {
                    //<<< matches[1], matches[2], matches[3] >>>;
                    1.0-(matches[1] => Std.atof)/1023.0 => _knob1;
                    1.0-(matches[2] => Std.atof)/1023.0 => _knob2;
                    matches[3] => Std.atoi => _sw1;
                }
            }
        }
    }
    
    
    fun float knob1() { return _knob1; }
    fun float knob2() { return _knob2; }
    fun int switch1() { return _sw1; }
}    


//Panel panel;
//panel.open(1);

//while(true){
//    <<< panel.knob1(), panel.knob2(), panel.switch1() >>>;
//    25::ms => now;
//}

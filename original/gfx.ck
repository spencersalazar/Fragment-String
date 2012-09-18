public class gfx
{
    static OscSend @ send;
    
    fun static void mode(int m, int hand)
    {
        if(hand == 0)
            send.startMsg("/smeaky/mode/left, i");
        else if(hand == 1)
            send.startMsg("/smeaky/mode/right, i");
        send.addInt(m);
    }
    
    fun static void level(float l)
    {
        send.startMsg("/smeaky/level, f");
        send.addFloat(l);
    }
}

new OscSend @=> gfx.send;
gfx.send.setHost("localhost", 6449);

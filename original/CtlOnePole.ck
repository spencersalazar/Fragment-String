public class CtlOnePole
{
    20::ms => dur rate;
    
    0.9 => float m_a;
    0.1 => float m_b;
    
    0 => float x;
    0 => float y;
    
    spork ~ go();
    
    fun float a(float _a)
    {
        _a => m_a;
        1-Std.fabs(m_a) => m_b;
        return m_a;
    }
    
    fun float tick(float f)
    {
        f => x;
        return y;
    }
    
    fun float last()
    {
        return y;
    }
    
    fun void go()
    {
        while(true)
        {
            x*m_b + y*m_a  => y;
            onUpdate();
            rate => now;
        }
    }
    
    // override to do fun stuff on update
    fun void onUpdate() { }
}

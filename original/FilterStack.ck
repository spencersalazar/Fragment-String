
public class FilterStack extends Chubgraph
{
    BPF filter[];
    float m_freq;
    float m_Q;
    
    fun void init(int numFilters)
    {
        BPF theFilters[numFilters];
        theFilters @=> filter;
        
        Gain master => outlet;
        
        for(int i; i < filter.cap(); i++)
        {
            inlet => filter[i] => master;
        }
        
        220 => freq;
        10 => Q;
    }
    
    fun int numFilters() { return filter.cap(); }
    
    fun float freq(float f)
    {
        f => m_freq;
        for(int i; i < filter.cap(); i++)
        {
            m_freq * i => filter[i].freq;
        }
        
        return m_freq;
    }
    
    fun float Q(float _q)
    {
        _q => m_Q;
        for(int i; i < filter.cap(); i++)
        {
            m_Q => filter[i].Q;
        }
        
        return m_Q;
    }
    
    fun float Q() { return m_Q; }
    
    fun float gainAt(int i, float g)
    {
        if(i >= 0 && i < filter.cap())
        {
            g => filter[i].gain;
            return g;
        }
        
        return 0.0;    
    }
}



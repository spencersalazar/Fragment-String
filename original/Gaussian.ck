public class Gaussian
{
    fun static float generate()
    {
        // see http://en.wikipedia.org/wiki/Normal_distribution#Generating_values_from_normal_distribution
        Std.rand2f(0,1) => float u;
        Std.rand2f(0,1) => float v;
        
        return Math.sqrt(-2*Math.log(u))*Math.cos(2*Math.PI*v);
    }
}
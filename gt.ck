Hid gt;
HidMsg msg;
gt.openJoystick(0);

while(true)
{
    gt => now;
    while(gt.recv(msg))
    {
        if(msg.type == Hid.AXIS_MOTION && msg.which == Std.atoi(me.arg(0)))
        {
            chout <= msg.axisPosition <= "\n";
        }
    }
}
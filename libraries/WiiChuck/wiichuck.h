
#include <WProgram.h>

class WiiChuck 
{
public:
	unsigned int joy_x;
	unsigned int joy_y;
	unsigned int acc_x;
	unsigned int acc_y;
	unsigned int acc_z;
	unsigned int btn_c;
	unsigned int btn_z;
	
	boolean inSync;
	WiiChuck() : inSync(false), joy_x(0), joy_y(0), acc_x(0), acc_y(0), acc_z(0), btn_c(0), btn_z(0) {};
	void init();
	boolean readData();
}
;
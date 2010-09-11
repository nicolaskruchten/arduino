
#include <WProgram.h>

class MotorController {
	private:
		int tx;
    public:
	MotorController() : tx(0) {};
      void init(int txPin, int resetPin);
	  void SetMotor(int motorIndex, int speed);
      void SetMotor(int motorIndex, int speed, boolean GoForward);
  }
;
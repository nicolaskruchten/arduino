
#include <WProgram.h>

  class MotorController {
    public:
      MotorController() {};
      void init(int txPin, int resetPin);
	  void SetMotor(int motorIndex, int speed);
      void SetMotor(int motorIndex, int speed, boolean GoForward);
    private:
    	int tx;
  };

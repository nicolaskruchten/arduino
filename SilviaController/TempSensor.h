#include <Wire.h>
#include <TypeK.h>

class TempSensor {
  private:
    // updated at intervals of DELAY ms    
    int32_t ambs[12];
    int32_t sumamb;
    
    void get_samples();
    int32_t get_ambient();
    void init_ambient();
    void avg_ambient();
    
  public:
    TempSensor() : temp(0), sumamb(0), avgamb(0) {}
  
    void init();
    
    void update();
    
    int32_t temp;
    int32_t avgamb;
};





  

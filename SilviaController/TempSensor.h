// aj_logger.pde
//
// 4-chan TC w/ mcp3424 and mcp9800

// Support for pj_logger.pde
// Jim Gallt 
// Version: 20100626

// This code was adapted from the a_logger.pde file provided
// by Bill Welch.


// ------------------------ conditional compiles

#define DELAY 300   // ms between ADC samples (tested OK at 270)
#define RES_11      // resolution on ambient temp chip
#define NAMBIENT 12  // number of ambient samples to be averaged
#define CFG CFG8  // select gain = 8 on ADC
#define BAUD 9600  // serial baud rate
#define TC_TYPE TypeK  // thermocouple type / library

// ---------------------------- calibration of ADC and ambient temp sensor
#define CAL_OFFSET  ( -1 )  // microvolts
#define CAL_GAIN 1.0035
#define TEMP_OFFSET ( 0.55 );  // Celsius offset


// -------------- ADC configuration

#define ADC_RDY 7  // ready bit
#define ADC_C1  6  // channel selection bit 1
#define ADC_C0  5  // channel selection bit 0
#define ADC_CMB 4  // conversion mode bit (1 = continuous)
#define ADC_SR1 3  // sample rate selection bit 1 (11 = 18 bit)
#define ADC_SR0 2  // sample rate selection bit 0
#define ADC_G1  1  // gain select bit 1
#define ADC_G0  0  // gain select bit 0

#define CFG1 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) ) // 18 bit, gain = 1
#define CFG2 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G0) ) // 18 bit, gain = 2 
#define CFG4 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) ) // 18 bit, gain = 4 
#define CFG8 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) | _BV(ADC_G0) ) // 18 bit, gain = 8

#define A_BITS9  B00000000
#define A_BITS10 B00100000
#define A_BITS11 B01000000
#define A_BITS12 B01100000

#define BITS_TO_uV 15.625  // LSB = 15.625 uV

// -------------------- MCP9800 configuration
#ifdef RES_12
#define A_BITS A_BITS12
#endif
#ifdef RES_11
#define A_BITS A_BITS11
#endif
#ifdef RES_10
#define A_BITS A_BITS10
#endif
#ifdef RES_9
#define A_BITS A_BITS9
#endif

// --------------------------
#define A_ADC 0x68
#define A_AMB 0x48

// --------------------------------------------------------------
// global variables

class TempSensor {
  private:
       
    // updated at intervals of DELAY ms    
    int32_t ambs[NAMBIENT];
    int32_t sumamb;
    
    
    // --------------------------------------------------------------------------
    void get_samples()
    {
      int stat;
      byte a, b, c, rdy, gain, mode, ss;
      int32_t v;
      TC_TYPE tc;
      float tempC;
    
      Wire.requestFrom(A_ADC, 4);
      a = Wire.receive();
      b = Wire.receive();
      c = Wire.receive();
      stat = Wire.receive();
    
      rdy = (stat >> 7) & 1;
      mode = (stat >> 4) & 1;
      ss = (stat >> 2) & 3;
      gain = stat & 3;
      
      v = a;
      v <<= 24;
      v >>= 16;
      v |= b;
      v <<= 8;
      v |= c;
      
      // convert to microvolts
      v = round(v * BITS_TO_uV);
    
      // divide by gain
      v /= 1 << (CFG & 3);
      v += CAL_OFFSET;  // adjust calibration offset
      v *= CAL_GAIN;    // calibration of gain
      
      //v is now in microvolts
    
      // convert mV to temperature using ambient temp adjustment and multiply by 100 to preserve precision
      tempC = tc.Temp_C( 0.001 * v, avgamb * 0.01 );
      tempC += TEMP_OFFSET;
      temp = tempC * 100;
      
      Wire.beginTransmission(A_ADC);
      Wire.send(CFG | (0 << 5) );
      Wire.endTransmission();
    }
    
    // ---------------------------------------------------------------------
    int32_t get_ambient()
    {
      byte a,b;
      int32_t v,va,vb;
    
      Wire.beginTransmission(A_AMB);
      Wire.send(0); // point to temperature reg.
      Wire.endTransmission();
      Wire.requestFrom(A_AMB, 2);
      a = Wire.receive();
      b = Wire.receive();
      va = a;
      vb = b;
      
    #ifdef RES_12
    // 12-bit code
      v = ( ( va << 8 ) +  vb ) >> 4;
      v = ( 100 * v ) >> 4;
    #endif
    #ifdef RES_11
    // 11-bit code
      v = ( ( va << 8 ) +  vb ) >> 5;
      v = ( 100 * v ) >> 3;
    #endif
    #ifdef RES_10
    // 10-bit code
      v = ( ( va << 8 ) +  vb ) >> 6;
      v = ( 100 * v ) >> 2;
    #endif
    #ifdef RES_9
    // 9-bit code
      v = ( ( va << 8 ) +  vb ) >> 7;
      v = ( 100 * v ) >> 1;
    #endif
    
     return v;
    
    // FIXME: test temps below freezing.
      
    }
    
    // --------------------------------------------------------------------
    void init_ambient() {
      for(int i = 0; i < NAMBIENT; i++ ) {
        int32_t ambient = get_ambient();
        delay(DELAY);
        sumamb += ambient;
        ambs[i] = ambient;
      }
    }
    
    // ----------------------------------------------------------------------
    void avg_ambient() {
      int32_t ambient = get_ambient();
      if( NAMBIENT <= 1 ) 
        avgamb = ambient;
      else {
        sumamb += ambient - ambs[0];  // delete oldest value
        for(int i = 0; i < NAMBIENT-1; i++ ) {
          ambs[i] = ambs[i+1];
        }
       ambs[NAMBIENT-1] = ambient;
       avgamb = sumamb / NAMBIENT;
      }
    }  
    
  public:
    int32_t temp;
    int32_t avgamb;
    
    TempSensor() : temp(0), sumamb(0), avgamb(0) {}
  
    void init()
    {
      byte a;
      Wire.begin();
    
      // configure mcp3424
      Wire.beginTransmission(A_ADC);
      Wire.send(CFG);
      Wire.endTransmission();
    
      // configure mcp9800.
      Wire.beginTransmission(A_AMB);
      Wire.send(1); // point to config reg
      Wire.send(A_BITS); 
      Wire.endTransmission();
    
      // see if we can read it back.
      Wire.beginTransmission(A_AMB);
      Wire.send(1); // point to config reg
      Wire.endTransmission();
      Wire.requestFrom(A_AMB, 1);
      a = 0xff;
      if (Wire.available()) {
        a = Wire.receive();
      }
      if (a != A_BITS) {
        Serial.println("# Error configuring mcp9800");
      } else {
        Serial.println("# mcp9800 Config reg OK");
      }
      
      // initialize ambient temperature ring buffer
      init_ambient();
    }
    
    void update()
    {
      avg_ambient();
      get_samples();
    }
    
};





  

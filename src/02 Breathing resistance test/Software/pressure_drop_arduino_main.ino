// Initialize all the pins and constants
#define flowPin         A1  // pin A1 is being used for the pressure sensor to determine the flow
#define pressurePin     A0  // pin A2 is being used for the pressure sensor to determine the pressure drop
#define fanPWMpin       3  // Pin D3 is being used to send the PWM signal to the fan, this is the brown cable
#define fanSensor       8  // Pin D8 is being used for the tachograph of the fan, this is the yellow cable
#define relaisPin       7  // Pin D7 is being used for the safety relais (too high pressure value will switch of fan)
#define pres_modePin    12 // Pin D12 determines which mode is being used for the pressure sensor (HIGH or LOW) for (Nonlin or lin) respectively
#define flow_modePin    13 // Pin D13 determines which mode is being used for the flow pressure sensor (HIGH or LOW) for (Nonlin or lin) respectively
#define max_sensor_val  910 // max value for the sensor where it will not be damaged
#define Puls            4  // Number of pulses from the fan for the PWM signal, 4 pulses is 1 rotations
#define n_samples       10 // Number of samples per PWM value
#define PWM_min         20  // min PWM value (this can be set when the fan only starts spinning at higher PWM values)
#define PWM_max         255 // max PWM value
#define pressure_nonlin true // TRUE is nonlin mode for the pressure sensor, FALSE is lin mode for the pressure sensor
#define flow_nonlin     true // TRUE is nonlin mode for the flow pressure sensor, FALSE is lin mode for the flow pressure sensor

// initialize all variables
int measured_flow       = 0;  // measured value for the flow [0-1023]
int measured_pressure   = 0;  // measured value for the pressure [0-1023]
bool safety_switch      = true; // safety switch, true if the measurement can continue, false is it is not safe to do so
int i_PWM               = PWM_min;  // i value for PWM sweep
int i_measurement       = 0;  // i for in the measurement
unsigned long SensorPulsTime; //

// set the mode for the pressure sensors nonlin is better accuracy around the zero point of the sensor
void setpressureSensors() {
  if (pressure_nonlin ==  true){
    digitalWrite(pres_modePin,HIGH);
  }
  else {
    digitalWrite(pres_modePin,LOW);
  }

  if (flow_nonlin ==  true){
    digitalWrite(flow_modePin,HIGH);
  }
  else {
    digitalWrite(flow_modePin,LOW);
  }
}


void setup() {
  Serial.begin(9600);
  pinMode(fanSensor, INPUT);
  pinMode(relaisPin, OUTPUT);
  pinMode(pres_modePin, OUTPUT);
  pinMode(flow_modePin, OUTPUT);
  digitalWrite(fanSensor,HIGH);
  digitalWrite(relaisPin, HIGH);

  setpressureSensors();
}

void loop() {
  // Run the script for the lowest PWM value, this script will only start when
  // the Serial monitor is avalible (also open the relais port)
  if (i_PWM==PWM_min){
    if (Serial.available()){
      analogWrite(fanPWMpin, i_PWM);
      digitalWrite(relaisPin, LOW);
      delay(1000);
      i_PWM++;
      Serial.println("Nieuwe meting gestart");
    }
  }

  // Run the script for different PWM values
  if (i_PWM>PWM_min && i_PWM<PWM_max){
    i_PWM = do_measurement(i_PWM);
  }

  // when the script is completed end the serial line and print end statement
  if (i_PWM==PWM_max){
    analogWrite(fanPWMpin, 0);
    digitalWrite(relaisPin, HIGH);
    Serial.println("end");
    Serial.end();
    i_PWM++;
  }

}

// Doing the measurement
int do_measurement(int i_PWM){
  analogWrite(fanPWMpin, i_PWM);          //write the analog value to the fan

  // printing the measurement 10 times the serial port for each PWM value (to 
  // settle the system)
  for (int i_measurement=0 && i_PWM!=PWM_max; i_measurement < 10; i_measurement++) {
    // measure the flow pressure and pressure drop, these are non processed 
    // values and dependent of the type of sensor
    measured_flow = analogRead(flowPin);
    measured_pressure = analogRead(pressurePin);
    SensorPulsTime = pulseIn(fanSensor, LOW, 300000);

    // print the values to the Serial monitor
    Serial.print("PWM: ,");
    Serial.print(i_PWM);
    Serial.print(", flow sensor value ,");
    Serial.print(measured_flow);
    Serial.print(", pressure sensor value ,");
    Serial.print(measured_pressure);
    Serial.print(", SensorPulsTime ,");
    Serial.println(SensorPulsTime);

    // safety switch, if the sensor is overloaded the system will shut down and 
    // stop measurement to prevent damage to the sensors.
    if (measured_pressure>max_sensor_val or measured_flow>max_sensor_val){
      digitalWrite(relaisPin, HIGH);
      i_measurement = 11;
      safety_switch = false;
      i_PWM = PWM_max;
      Serial.println("end");
      Serial.end();
      break;
    }
    // delay for the system to settle, this is 100 ms, minus the time which has 
    // elapsed to find the sensor pulse time
    delayMicroseconds(100e3-SensorPulsTime);
  }

  // increase and return PWM value to the main script 
  i_PWM++;
  return i_PWM;
}

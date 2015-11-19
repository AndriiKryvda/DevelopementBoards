//Sample using LiquidCrystal library
#include <LiquidCrystal.h>
#include <math.h>
#include <dht11.h>

dht11 DHT11;
#define DHT11PIN 2
#define RELAY1 1

/*******************************************************
 * 
 * This program manages a cooler
 * v0.4
 * Andrii Kryvda, July 2015
 * 
 ********************************************************/

// select the pins used on the LCD panel
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

// define some values used by the panel and buttons
int lcd_key     = 0;
int adc_key_in  = 0;
#define btnRIGHT  0
#define btnUP     1
#define btnDOWN   2
#define btnLEFT   3
#define btnSELECT 4
#define btnNONE   5

int m_baseTemperature = 29;    // base temperature, is configurable by the keys
int m_minTemperature = 20;     // minimal temparature which can be set
int m_maxTemperature = 40;     // maximum temparature which can be set
int m_temperatureValues[5];
int m_temperatureThreshold = 1;
int m_currentTemperature = 0;  // current temperature
int m_currentHumidity = 0;     // current humidity
boolean m_showTempOrHumidity = true;  // True - shot temperature, False - show humidity

int m_trigger01_checkpoint_seconds = 3600;
int m_trigger01_threshold_secoonds = 3600;

boolean m_isAction = false;

char m_progressSymbol = '*';
int m_progressIndx = 0;

int m_displayTickBase = 5;
int m_displayTick = m_displayTickBase;

// read the buttons
int read_LCD_buttons()
{
  adc_key_in = analogRead(0);      // read the value from the sensor 
  // my buttons when read are centered at these valies: 0, 144, 329, 504, 741
  // we add approx 50 to those values and check to see if we are close
  if (adc_key_in > 1000) return btnNONE; // We make this the 1st option for speed reasons since it will be the most likely result
  // For V1.1 us this threshold
  if (adc_key_in < 50)   return btnRIGHT;  
  if (adc_key_in < 250)  return btnUP; 
  if (adc_key_in < 450)  return btnDOWN; 
  if (adc_key_in < 650)  return btnLEFT; 
  if (adc_key_in < 850)  return btnSELECT;  

  // For V1.0 comment the other threshold and use the one below:
  /*
 if (adc_key_in < 50)   return btnRIGHT;  
   if (adc_key_in < 195)  return btnUP; 
   if (adc_key_in < 380)  return btnDOWN; 
   if (adc_key_in < 555)  return btnLEFT; 
   if (adc_key_in < 790)  return btnSELECT;   
   */
  return btnNONE;  // when all others fail, return this...
}

void setup()
{
  lcd.begin(16, 2);              // start the library
  
  lcd.setCursor(0,0);
  lcd.print("Base");
  
  lcd.setCursor(0,1);
  lcd.print("Temp");
  
  // set last temperature values to "0"
  for(int i = 0; i < sizeof(m_temperatureValues)/sizeof(int); i++)
  {
    m_temperatureValues[i] = 0;
  }
  
  // Initialise the Arduino data pins for OUTPUT
  pinMode(RELAY1, OUTPUT);
}

void loop()
{
  int baseTemp = m_baseTemperature;

  lcd_key = read_LCD_buttons();  // read the buttons

  switch (lcd_key)               // depending on which button was pushed, we perform an action
  {
  case btnUP:
    {
      ChangeBaseTemperature(1);
      break;
    }
  case btnDOWN:
    {
      ChangeBaseTemperature(-1);
      break;
    }
  }

  delay(200);
  
  //show base temperature
  if (baseTemp != m_baseTemperature || GetUptime() < 5)
  {
    lcd.setCursor(7,0);
    lcd.print(m_baseTemperature);
    lcd.print(" C");
  }
  
  // show temperature and humidity
  ShowTemperature();
}


void ShowTemperature()
{
  // update dysplay once in 5 cycles
  if (m_displayTick > 0)
  {
    m_displayTick = m_displayTick - 1;
    return; 
  }
  else
  {
    m_displayTick = m_displayTickBase; 
  }
  
  // show temperature
  int temperature = RegisterTemperature();
  ShowTemperatureValue(temperature);
  
  // run temperature check after 5 sec of the startup
  if (GetUptime() > 5)
  {
    boolean checkTemp = CheckTemperature();
  }

  ShowProgressBar(5); 
}


void ShowTemperatureValue(int temperature)
{
  lcd.setCursor(0,1);
  lcd.print("Temp");  

  lcd.setCursor(7,1);
  lcd.print(temperature);
  lcd.print(" C");
}


int GetAverageTemperature()
{
  // calculate average value
  int temperature = 0;
  int count = 0;
  for (int i = 0; i < sizeof(m_temperatureValues)/sizeof(int); i++)
  {
    if (m_temperatureValues[i] > 0)
    {
      temperature = temperature + m_temperatureValues[i];
      count = count + 1;
    }
  }
  
  if (count > 0)
  {
    temperature = temperature / count;
  }
  return temperature;
}


boolean CheckTemperature()
{
  // calculate average value
  int temperature = GetAverageTemperature();
  
  // if no action and temperature+threashold greater than base_temperature then run Action
  if (!m_isAction && temperature >= m_baseTemperature + m_temperatureThreshold)
  {
     DoAction(true);
     return true;
  }
  else if (m_isAction && temperature + m_temperatureThreshold <= m_baseTemperature)
  {
    DoAction(false);
    return true;
  }
  
  return false;
}


void DoAction(boolean startAction)
{
  m_isAction = startAction;
  
  if(startAction)
  {
    // start the cooler
    lcd.setCursor(15,1);
    lcd.print("*");
    
    TurnRelay(true);
  }
  else
  {
    // stop the coller
    lcd.setCursor(15,1);
    lcd.print(" ");
    
    TurnRelay(false);
  }
}


int RegisterTemperature() 
{
  int chk = DHT11.read(DHT11PIN);
  m_currentTemperature = (int)DHT11.temperature;
  m_currentHumidity = (int)DHT11.humidity;
  
  //save temperature into the array of last temparature values
  for (int i = sizeof(m_temperatureValues)/sizeof(int) - 1; i > 0; i--)
  {
    m_temperatureValues[i] = m_temperatureValues[i-1];
  }
  m_temperatureValues[0] = m_currentTemperature;
  
  return GetAverageTemperature();
}


void ShowProgressBar(int index)
{ 
  if (m_progressIndx == 0) 
  {
    lcd.setCursor(index,0);
    lcd.print(m_progressSymbol);
    lcd.setCursor(index,1);
    lcd.print(" ");
    m_progressIndx = m_progressIndx + 1;
  }
  else
  {
    lcd.setCursor(index,0);
    lcd.print(" ");
    lcd.setCursor(index,1);
    lcd.print(m_progressSymbol);
    m_progressIndx = 0;
  }
}


void ChangeBaseTemperature(int delta)
{
  m_baseTemperature = m_baseTemperature + delta;
  
  if (m_baseTemperature < m_minTemperature)
  {
    m_baseTemperature = m_minTemperature;
  }
  if (m_baseTemperature > m_maxTemperature)
  {
    m_baseTemperature = m_maxTemperature;
  }
}


int GetUptime()
{
  return millis()/1000;
}


void TurnRelay(bool turn)
{
  if (turn == true)
  {
    digitalWrite(RELAY1,HIGH);           // Turns ON Relays 1
  }
  else
  {
    digitalWrite(RELAY1,LOW);           // Turns ON Relays 1
  }
}


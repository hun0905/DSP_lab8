int pot = A0;
int val = 0;
int start_time;
int now_time;
int begin=1000;
int lowest=1024;
int highest=0;
int num=0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(pot,INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  start_time = micros();
  val = analogRead(pot);    //read analog input

  if(num<2500){
    num = num+1;
    if(lowest>val){
      lowest=val;
    }
    if(highest<val){
      highest=val;
    }
  }
  else{
    val = map(val,lowest,highest,0,255);    //mapping 
    Serial.println(val,DEC); 
  }
  if(val<lowest)
    val=lowest;
  if(val>highest)
    val=highest;
  //Serial.println(val,DEC);     //print on Matlab  
  now_time = micros();
  while(now_time-start_time<4000){    //sample rate  
    now_time = micros();
  }
}
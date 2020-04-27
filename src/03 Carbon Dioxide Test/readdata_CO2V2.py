##############
## Script listens to serial port and writes contents into a file
##############
## requires pySerial to be installed 
import serial
import datetime
import time

# Determine which serial is connected
import serial.tools.list_ports
comlist = serial.tools.list_ports.comports()
connected = []
i = 0
for element in comlist:
    connected.append(element.device)

# List the different com ports which are in use
for x in connected:
	print("[",i,"]"," ", x)
	i=i+1

# Prompt user for which arduino is connected
i = int(input("Which com port do you wish to use?: "))
serial_port = connected[i]

# Prompt user for which setup is being used
i = int(input("Which setup are you using?: "))
setup_type = "setup_%d" % i

# Prompt user for which sample is being used
i = int(input("Which sample are you using?: "))
sample_number = "sample_%s" % str(i).zfill(3)

# Create a timestamp for the output name of the file
x = datetime.datetime.now()

# Create a filename to which the file is being saved
name =  "./data/output_%s_%s_%d_%s_%s_%s_%s_%s.csv" % (sample_number, setup_type, x.year, str(x.month).zfill(2), str(x.day).zfill(2), str(x.hour).zfill(2), str(x.minute).zfill(2), str(x.second).zfill(2))
write_to_file_path = name
output_file = open(write_to_file_path, "w+")

# Open the serial monitor and prompt the script to start the measurement
baud_rate = 9600 #In arduino, Serial.begin(baud_rate)
ser = serial.Serial(serial_port, baud_rate, timeout=5)
time.sleep(1)
ser.write(b"1")

start_time = time.time()
n = 0
DT = 50
AV = 0
S1 = 0
S2 = 0
nlist = []
# Let the arduino do the measurement and store data to csv file
while True:
    n = n+1
    line = ser.readline();
    #print(f"Binary: \"{line}\"")
    line = line.decode("utf-8") #ser.readline returns a binary, convert to string
    #print(f"Decoded: \"{line}\"")
    # t = (time.time() - start_time)
    line = (f"t_%s_%s" % (time.time() - start_time, line))
    output_file.write(line)
    if line.startswith("end"):
        print("Meting is afgelopen/ afgebroken")
        ser.close()
        break
    if n > DT:
        nlist.append(line)
        if n > DT+4:
            for i in range(3):
                for j in range(len(nlist)):
                    if nlist[j].find("Analog value") != -1 and AV == 0 and S1 == 0 and S2 == 0:
                        line = nlist[j]
                        print(f"Decoded: \"{line}\"")
                        AV = AV+1
                    if nlist[j].find("Sensor 1") != -1 and AV == 1 and S1 == 0 and S2 == 0:
                        line = nlist[j]
                        print(f"Decoded: \"{line}\"")
                        S1 = S1+1
                    if nlist[j].find("Sensor 2") != -1 and AV == 1 and S1 == 1 and S2 == 0:
                        line = nlist[j]
                        print(f"Decoded: \"{line}\"")
                        S2 = S2+1

            n = 0
            AV = 0
            S1 = 0
            S2 = 0
            nlist = []

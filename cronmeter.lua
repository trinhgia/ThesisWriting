
-- GLOBAL VARIABLE DECLARATIONS --
----------------------------------
OBIS_total_imported_power = "2.8.0" -- Total imported hour according to OBIS code
char_buff ={}  --- buffer for Lora data in byte format                                                                                                                                              
hex_buff ={}   --- buffer for Lora data in hex format
result = ""    --- bufer for storing data which will be sent over lora
-- END OF DECLEARATION --

-- FUNCTIONS DECLARATION --
----------------------------------
-- Sleep/Delay funtion in second --
local clock = os.clock
function sleep(n)  -- n in seconds
  local t0 =clock()
  while clock() - t0 <=n do end
end
-- End function --

-- Intialize serial port using for reading data from meter throguh optical port --
rs232 = require ("luars232")
port_name_meter = "/dev/ttyUSB0"
local out = io.stderr
local e, meter = rs232.open(port_name_meter)

assert (meter:set_baud_rate(rs232.RS232_BAUD_300) == rs232.RS232_ERR_NOERROR)
assert (meter:set_data_bits(rs232.RS232_DATA_7) == rs232.RS232_ERR_NOERROR)
assert (meter:set_parity(rs232.RS232_PARITY_EVEN) == rs232.RS232_ERR_NOERROR)
assert (meter:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
assert (meter:set_flow_control(rs232.RS232_FLOW_OFF) == rs232.RS232_ERR_NOERROR)

-- Initialize serial port using for communicating with Lora device
rs232 = require ("luars232")                                                                                                                                   
port_name_lora = "/dev/ttyS1"                                                                                                                                  
local out = io.stderr                                                                                                                                          
local e1, lora = rs232.open(port_name_lora)                                                                                                                    
                                                                                                                                  
assert (lora:set_baud_rate(rs232.RS232_BAUD_57600) == rs232.RS232_ERR_NOERROR)                                                                                 
assert (lora:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)                                                                                     
assert (lora:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)                                                                                   
assert (lora:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)                                                                                     
assert (lora:set_flow_control(rs232.RS232_FLOW_OFF) == rs232.RS232_ERR_NOERROR)                                                                                
-- End of initialization                                                                                                                                                                                                                                               

-- Create log file funtion --
function logfile()
   local day = os.date("%d%m%Y")
   local default = "meterlog"
   local file = default.."."..day
   local f = io.open(tostring(file) ,"r")
   if not f then
      os.execute( "touch meterlog.$(date '+%d%m%Y')")
      f = io.open("/"..tostring(file) , "a")
		print (" ")
    else
      io.close(f)
	  print ("") 
   end
    local file_to_open = io.open("/"..tostring(file), "a")
   return file_to_open
end
-- End function ----

-- Function to write data to log file --
function write_file (data)
log = logfile()
local hour = os.date("%H")
local minute = os.date("%M")
log:write("H"..hour.."M"..minute..":"..OBIS_total_imported_power..":"..data .."\n")
io.close(log)
end
-- End function

-- Querry/Polling Function for reading data from meter --

function meter_querry ()
local data_buff_1 = ""
local query_end = false
while (query_end == false)
do 
  local err,data_read,size = meter:read(1,1200)
  assert (e == rs232.RS232_ERR_NOERROR)
  data_buff_1 = data_buff_1..tostring(data_read) 
 if (data_read ~= nil and data_read == "\n")
  then 
     query_end = true
  end 
end
print (data_buff_1)
return data_buff_1
end
--- end function

-- DATA READOUT PHASE --
function read_meter()
local latch = false
local err,len_written = meter:write(string.char(0x2f,0x3f,0x21,0x0d,0x0a)) --("/?!\r\n")
assert(e == rs232.RS232_ERR_NOERROR) 
local result1=""
result1= meter_querry() -- Using polling function for gettig response from meter
if (result1 == "/LGZ4ZMF100AC.M26")
then
print(result1)
end
-- Start querrying data from meter --
local err, len_written = meter:write(string.char(0x06,0x30,0x30,0x30,0x0d,0x0a)) 
assert (e == rs232.RS232_ERR_NOERROR)
local result2 =""
result2 = meter_querry()
print (result2)
local status = false
local filtered =""
local data_buff = ""
local data_return= ""
sleep (0.2)
while (status == false ) do
  local err,data_read,size = meter:read (1,50)
  assert (e==rs232.RS232_ERR_NOERROR)
  data_buff = data_buff..tostring(data_read)
  -- Capture the data which is related to total imported power according to OBIS code
  filtered = string.match(data_buff, "^2.8.0")
  if (filtered == OBIS_total_imported_power and (tostring(data_read) == "\n"))
     then
      data_return = string.match (data_buff, "(%d%d%d%d%d%d.%d%d%d)")
	  print (data_buff)
	  data_buff = ""
	  latch = true
  elseif (tostring(data_read) == "\n") 
  then
  print (data_buff)
  data_buff = ""			 
  elseif (tostring(data_read) == "!")
  then
   print (data_buff)
   data_buff = ""
  elseif (data_read == nil)
  then
   status = true
  end
  end
 print ("end")
return data_return, latch
end
-- End function --

------------------------------------------------------------------
------------------------------------------------------------------ 
-- read from serial port of Lora device --                                                                                                                                            
function read_serial ()                                                                                                                                        
local query_end = false                                                                                                                                        
local data_buff = ""                                                                                                                                           
while (query_end == false)                                                                                                                                     
do                                                                                                                                                             
  local err,data_read,size = lora:read(1,200)                                                                                                                  
  assert (e1 == rs232.RS232_ERR_NOERROR)                                                                                                                       
  data_buff = data_buff..tostring(data_read)                                                                                                                   

 if (data_read == "\n")                                                                                                                                        
  then                                                                                                                                                         
  print (data_buff)                                                                                                                                            
  end                                                                                                                                                          
if (data_read == nil)                                                                                                                                          
  then                                                                                                                                                         
  query_end = true                                                                                                                                             
  end                                                                                                                                                          
end                                                                                                                                                            
return (data_buff)                                                                                                                                             
end   
-- End function --                                                                                                                                                         
-- polling response from Lora device after send command --                                                                                                                                                              
function polling ()                                                                                                                                            
local query_end = false                                                                                                                                        
local data_buff = ""                                                                                                                                           
while (query_end == false)                                                                                                                                     
do                                                                                                                                                             
  local err,data_read,size = lora:read(1,200)                                                                                                                  
  assert (e1 == rs232.RS232_ERR_NOERROR)                                                                                                                       
  data_buff = data_buff..tostring(data_read)                                                                                                                   
  if (data_read == "\n")                                                                                                                                       
        then                                                                                                                                                   
        query_end = true                                                                                                                                       
    end                                                                                                                                                        
end                                                                                                                                                            
print (data_buff)                                                                                                                                              
return (data_buff)                                                                                                                                             
end  
-- End function 

-- Send data from to lora device --                                                                                                                                                          
function mac_tx(port, data)                                                                                                                                    
   local data_send = ""                                                                                                                                        
   local command = "mac tx uncnf"                                                                                                                              
   data_send = command.." "..tostring(port).." "..tostring(data).."\r\n"                                                                                       
   local err,len_written = lora:write(data_send)                                                                                                               
   assert(e1 == rs232.RS232_ERR_NOERROR)                                                                                                                       
   print(data_send)                                                                                                                                            
   read_serial()                                                                                                                                               
end     
-- End function --

--Convert to hex --
function string2hex(input_string)                                                                                                                              
char_buff = {}                                                                                                                                                 
hex_buff = {}                                                                                                                                                  
local len = string.len(input_string)                                                                                                                            
for i=1 , len  do                                                                                                                                              
char_buff[i] =(string.byte(input_string,i))                                                                                                                    
end                                                                                                                                                            
for j = 1, len do                                                                                                                                              
hex_buff[j] = (string.format("%x",char_buff[j]))                                                                                                               
end                                                                                                                                                            
local converted = ""                                                                                                                                              
for k = 1, len do                                                                                                                                              
 converted = converted..tostring(hex_buff[k])                                                                                                                        
end                                                                                                                                                            
return converted                                                                                                                                               
end                                                                                                                                                                            
-- End function --

----- Main loop reading function ------
----- Once it call it will read all the data from meter -----

while true do
result = ""
local trap = false
result,trap = read_meter()
result = OBIS_total_imported_power..":"..result
print (result)
write_file (result)
if (trap == false ) then
sleep (10)
read_meter()
break
end
break
end
--------end -----------

-- Start transfer data to server -- 
result = string2hex(result)
mac_tx (1,result)                                                                                                                                         
polling()   


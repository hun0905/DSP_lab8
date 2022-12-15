
%%
%% Note that you have to fill the "???" parts by yourself before running the codes
%% You also can modify the codes to meet your applications
%%
%%
%% Clear and close everything
clear all;
fclose('all');
% Check if serial port object or any communication interface object exists
serialobj=instrfind;
if ~isempty(serialobj)
    delete(serialobj)
end
clc;
clear all;
close all;
%% ---------- Serial port setting ----------
s1 = serial('COM6');  % Construct serial port object
s1.BaudRate =115200;     % Define baud rate of the serial port
fopen(s1); % Connect the serial port object to the serial port

%% ---------- Sampling setting ----------
NSample = 250; % Number of sampling points, i.e., number of data points to acquire
fs = 250; % Sampling rate, check the setting in Arduino 

%% ---------- Display buffer setting ----------
display_length = 500; % Display buffer length 
display_buffer = nan(1, display_length);% Display buffer is a first in first out queue
time = nan(1,100);
buffer_ma = nan(1, display_length);
buffer_diff = nan(1, display_length);
buffer_flatten = nan(1, display_length);
buffer_threshold = nan(1, display_length);
time_axis =(0:display_length-1)*(1/fs); % Time axis of the display buffer
% Initialize figure object
figure
hold on
h_plot = plot(nan,nan);
h_plot2 = plot(nan,nan,'ro');
xlabel('Time(sec)');    
ylabel('Amplitude');
hold off 
tic
for i = 1:NSample*100
    data = fscanf(s1); % Read from Arduino
    data = str2double(data);
    if i < display_length
        display_buffer(i)=data;
        buffer_ma(i)=LP_filter(i,display_buffer,6);
        buffer_diff(i)=HP_filter(i,buffer_ma);
        buffer_flatten(i)=SquareFlatten(i,buffer_diff,9);
        buffer_threshold(i)=thresholding(i,buffer_flatten,2500);
    else
        display_buffer = circshift(display_buffer,-1); % first in first out
        display_buffer(end)=data;
        buffer_ma = circshift(buffer_ma,-1);
        buffer_ma(end)=LP_filter(display_length,display_buffer,6);
        buffer_diff = circshift(buffer_diff,-1);
        buffer_diff(end)=HP_filter(display_length,buffer_ma);
        buffer_flatten = circshift(buffer_flatten,-1);
        buffer_flatten(end)=SquareFlatten(display_length,buffer_diff,9);
        buffer_threshold = circshift(buffer_threshold,-1);
        buffer_threshold(end)=thresholding(display_length,buffer_flatten,2500);
    end
    if rem(i,10)==0
        [qrspeaks,locs] = findpeaks(buffer_threshold,time_axis,'MinPeakDistance',0.50);
        locs= locs;
        locs2 = round(locs./0.004);
        locs = locs(find(locs2>=1));
        locs2 = locs2(find(locs2>=1));
%         obj = findobj(gca,'type','line');
%         set(obj,'Marker','none');
        set(h_plot, 'xdata', time_axis, 'ydata', buffer_ma);
        %set(h_plot, 'xdata', locs, 'ydata', qrspeaks,'Marker','o');
        %set(hS,'xdata',locs,'ydata',qrspeaks)
        hold on
        set(h_plot2,'xdata',locs,'ydata',buffer_ma(locs2))
        if length(locs)>=2
            title([ 'Average Heart Rate: ' num2str( 60/(locs(end)-locs(end-1)) )])
        end

        drawnow;
    end
end
toc
fclose(s1);

function result=LP_filter(index,buffer,n)
    begin = max([index-n 0]);
    result=sum(buffer(begin+1:index))/(index-begin);
end

function result=HP_filter(index,buffer)
   if index > 4
       result = buffer(index)*2+buffer(index-1)-buffer(index-2)-2*buffer(index-3);
   else
       result = buffer(index);
   end
end
function result=SquareFlatten(index,buffer,n)
   begin = max([index-n 0]);
   result=sum(buffer(begin+1:index).^2)/(index-begin);
end

function result=thresholding(index,buffer,threshold)
    if buffer(index)>=threshold
        result = buffer(index);
    else
        result=0;
    end
end




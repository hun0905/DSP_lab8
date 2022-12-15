clear
close all

%% Load ECG data
% This raw ECG did not go through the analog notch filter
data = load('MIT database/hard/203m.mat');
fileID = fopen('MIT database/hard/203.txt')
c=textscan(fileID,'%s%s%s%s%s');
data2 = string(c{1});

ECG = data.val(1,:);
fs=360;

Npoint = length(ECG);

% calculate t_axis and f_axis
dt = 1 / fs; % time resolution
t_axis = (0 : dt : 1/fs*(Npoint - 1));
df = fs / Npoint; % frequency resolution
f_axis = (0:1:(Npoint-1))*df - fs/2;  % frequency axis (shifted)

% plot signal and its frequency spectrum
figure(1)
plot(t_axis, ECG)
xlim([0 5])
xlabel('Time (sec)')
ylabel('Quantized value')
title("Raw ECG Signal")

% figure(2)
% plot(f_axis, abs(fftshift(fft(ECG))))
% title('Frequency spectrum')




%ECG_mafiltered = ECG
ECG_mafiltered = LPF_filter(ECG,499);

figure(2)
plot(t_axis, ECG_mafiltered )
xlabel('Time (sec)')
ylabel('amplitude')
xlim([0 5])
ylim([800 1200])
title("move average filtered ECG Signal")


ECG_difffiltered = HPF_filter(500,ECG_mafiltered);
figure(3)
plot(t_axis, ECG_difffiltered )
xlabel('Time (sec)')
ylabel('amplitude')
xlim([0 5])
title("difference filtered ECG Signal")

ECG_flatten = SquareFlatten(ECG_difffiltered,499);
figure(4)
plot(f_axis, abs(fftshift(fft(ECG_flatten))))
xlim([-1 1])
title('Frequency spectrum')
figure(5)
plot(t_axis, ECG_flatten)
xlabel('Time (sec)')
ylabel('amplitude')
xlim([0 5])
title("flatten ECG Signal")
hold on
ECG_flatten=threshold(20,ECG_flatten);
[qrspeaks,locs] = findpeaks(ECG_flatten,'MinPeakDistance',216);
plot(t_axis(locs), ECG_flatten(locs),'ro')
hold off

figure(6)
plot(t_axis, ECG)
xlim([0 10])
xlabel('Time (sec)')
ylabel('Quantized value')
title("Raw ECG Signal with peak")
hold on
[qrspeaks,locs] = findpeaks(ECG_flatten,'MinPeakDistance',216);
plot(t_axis(locs), ECG(locs),'ro')
hold off
time = sec2MandS(t_axis(locs));
TruePositive=TP(time,data2);
FalseNegative=FN(time,data2);
FalsePositive=FP(time,data2);
Precision = TruePositive/(TruePositive+FalseNegative);
function result=LPF_filter(buffer,n)
    LPF = fir1(n,16/180,'low');
    result = conv(buffer,LPF,'same');
end
function result=HPF_filter(order,buffer)
     HPF = fir1(order,0.008,'high');
     HPF = [2 1  -1 -2];
     result = conv(buffer,HPF,'same');
end

function result=SquareFlatten(buffer,n)
   LPF = fir1(n,5/180,'low'); %4.5
   result = conv(buffer.^2,LPF,'same');

end
function result=sec2MandS(time)
   for i=1:length(time)
        min=mat2str(floor(time(i)/60));
        s = mat2str(round(mod(time(i),60),3));
        if length(s)==5
            s = "0"+s;
        end
        result(i)=min+":"+s;
   end
end
function result=TP(d1,d2)
    result=sum(ismember(d1,d2)) %sum(ismember(d1,d2))/length(d2)];
end
function result=FN(d1,d2)
    result=length(d2)-sum(ismember(d2,d1));
end
function result=FP(d1,d2)
    result=length(d1)-sum(ismember(d1,d2));
end
function result=threshold(n,buffer)
    result = zeros(1,length(buffer));
    for i=1:length(buffer)
        if i<=n || i>650000-n
            result(i)=buffer(i);
        else
            result(i)= sum(buffer(i-n:i+n))/(2*n);
        end
    end
end
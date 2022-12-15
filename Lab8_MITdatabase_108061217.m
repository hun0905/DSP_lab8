namelist=[dir('MIT database/easy/*.mat'),dir('MIT database/mid/*.mat'),dir('MIT database/hard/*.mat')];
TruePositive=0;
FalseNegative=0;
FalsePositive=0;
table = strings(16,5);
table(1,1)="Name"
table(1,2)="TP"
table(1,3)="FN"
table(1,4)="FP"
table(1,5)="Precision"
fclose('all');
for j=1:3
    for i=1:length(namelist)
        m_name=string(namelist(i,j).folder)+'\'+string(namelist(i,j).name);
        txt_name=string(namelist(i,j).folder)+'\'+string(namelist(i,j).name(1:end-5))+'.txt';
        ECG=load(m_name).val(1,:);
        fileID = fopen(txt_name);
        c=textscan(fileID,'%s%s%s%s%s');
        data2 = string(c{1});
        fs=360;
        Npoint = length(ECG);
        % calculate t_axis and f_axis
        dt = 1 / fs; % time resolution
        t_axis = (0 : dt : 1/fs*(Npoint - 1));
        df = fs / Npoint; % frequency resolution
        f_axis = (0:1:(Npoint-1))*df - fs/2;  % frequency axis (shifted)
        %ECG_mafiltered = LPF_filter(ECG,19);
        ECG_mafiltered = LP_filter(ECG,5);
        ECG_difffiltered = HP_filter(200,ECG_mafiltered);
        ECG_flatten = SquareFlatten(ECG_difffiltered,200);
        [qrspeaks,locs] = findpeaks(ECG_flatten,'MinPeakDistance',180);
        time = sec2MandS(t_axis(locs));
        TruePositive=TP(time,data2);
        FalseNegative=FN(time,data2);
        FalsePositive=FP(time,data2);
        Precision = TP(time,data2)/(FP(time,data2)+TP(time,data2));
        table((j-1)*5+i+1,1)=string(namelist(i,j).name);
        table((j-1)*5+i+1,2)=TruePositive;
        table((j-1)*5+i+1,3)=FalseNegative;
        table((j-1)*5+i+1,4)=FalsePositive;
        table((j-1)*5+i+1,5)= Precision;
    end
    
end
Precision = TruePositive/(TruePositive+FalseNegative);

function result=LP_filter(buffer,n)
    LPF = ones(1,n)/n;
    result = conv(buffer,LPF,'same');
    result = conv(result,LPF,'same');
end
function result=HP_filter(order,buffer)
   HPF = fir1(order,0.03,'high'); %0.035
   result = conv(buffer,HPF,'same');
end

function result=SquareFlatten(buffer,n)
   LPF = fir1(n,33/180,'low'); %27/180
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
    result=sum(ismember(d1,d2)) ;%sum(ismember(d1,d2))/length(d2)];
end
function result=FN(d1,d2)
    result=length(d2)-sum(ismember(d2,d1));
end
function result=FP(d1,d2)
    result=length(d1)-sum(ismember(d1,d2));
end



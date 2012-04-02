clear all;
close all;
clear java 
javaaddpath e:\files\papers\embedded\ax25
%======================================================================%
%======================================================================%
order_multiplier = 1;
ax25;

set(0,'defaultfigurecolor','w');
set(0,'defaultfigureInverthardcopy','off');
set(0,'defaultaxescolor','none');
set(0,'defaultfigureinvert','off');

% a bit of very uneven transmission by 4Z5LA
range=72302:73475;
plot(range,y(range),'k-');
a=axis;
axis([72302 73475 a(3) a(4)]);
get(gca)
set(gca,'XTick',[]);
set(gca,'YTick',[]);
set(gca,'Box','off');
set(gca,'XColor',[1 1 1]);
set(gca,'YColor',[1 1 1]);
%line([21398 22240],[0 0],'Color',[0 0 0],'LineStyle','--');
%legend('recorded signal','filtered signal','Location','NorthWest');
print -dtiff -r600 original_uneven.tif


% a segment from 4Z1PF
range=21398:22240;

plot(range,y(range),'k-',range,x(range),'r-');
a=axis;
axis([21398 22240 a(3) a(4)]);
get(gca)
set(gca,'XTick',[]);
set(gca,'YTick',[0]);
line([21398 22240],[0 0],'Color',[0 0 0],'LineStyle','--');
legend('recorded signal','filtered signal','Location','NorthWest');
print -dtiff -r600 original_and_filtered.tif

plot(range,x(range),'r-',range,z0(range),'g-',range,z1(range),'b-');
a=axis;
axis([21398 22240 a(3) a(4)]);
set(gca,'XTick',[]);
set(gca,'YTick',[0]);
line([21398 22240],[0 0],'Color',[0 0 0],'LineStyle','--');
legend('filtered signal','correlation with 1200 Hz','correlation with 2200 Hz','Location','NorthWest');
print -dtiff -r600 filtered_and_correlations.tif

plot(range,x(range),'r-',range,diff(range),'c-',range,fdiff(range),'m-');
a=axis;
axis([21398 22240 a(3) a(4)]);
set(gca,'XTick',[]);
set(gca,'YTick',[0]);
line([21398 22240],[0 0],'Color',[0 0 0],'LineStyle','--');
legend('filtered signal','d = corr(1200)-corr(2200)','d low-pass filtered','Location','SouthWest');
print -dtiff -r600 correlation_diffs.tif

plot(range,fdiff(range),'m-');
a=axis;
mn=min(fdiff(range));
mx=max(fdiff(range));
%axis([21398 22240 a(3) a(4)]);
axis([21398 22240 mn-(mx-mn)*0.3 mx+(mx-mn)*0.15]);
a=axis;
set(gca,'XTick',[]);
set(gca,'YTick',[0]);
line([21398 22240],[0 0],'Color',[0 0 0],'LineStyle','--');
legend('d low-pass filtered','Location','NorthWest');
flips=[];
for t=21398+1:22240
  if (fdiff(t-1)*fdiff(t)<=0)
      flips=[flips t];
      if length(flips)==1
          first=t;
      end
  end
end
%set(gca,'XTick',flips);
%set(gca,'XTick',flips);
ylabelpos = mn-(mx-mn)*0.15;
for i=1:length(flips)
    line([flips(i) flips(i)],[a(3) a(4)],'Color',[0 0 0],'LineStyle','--');
    if i<length(flips)
        periods = (flips(i+1)-flips(i)) / samples_per_bit;
        h=text((flips(i+1)+flips(i))/2, ylabelpos ,sprintf('%.3f',periods));
        get(h)
        set(h,'HorizontalAlignment','center');
        set(h,'VerticalAlignment','middle');
        set(h,'Rotation',-90);
    end
end

print -dtiff -r600 bit_periods.tif

%return


%======================================================================%
%======================================================================%
Fs = 11025;
[H,F]=freqz(r_b_full{2,3},1,2048,Fs);
db=20*log(abs(H))/log(10);

Ht=freqz(r_b_full{2,3},1,[1200 2200],Fs)
Ht=20*log(abs(Ht))/log(10);

desired_x = [0  900 1200 2200 2500 Fs/2];
desired_y = [0    0  0.5   1   0   0];
desired_y = 20*log(abs(desired_y))/log(10);

%plot(F,db,'k-',desired_x,desired_y,'r-');
plot(F,db,'k-');
%get(gca)
set(gca,'YTick',[-120 -80 -40 -6 0]); 
set(gca,'XTick',[0 1200 2200 5500]); 
axis([min(F) max(F) min(db) 10]);
line([min(F) max(F)],[Ht(1) Ht(1)],'Color',[0 0 0],'LineStyle','--');
line([min(F) max(F)],[Ht(2) Ht(2)],'Color',[0 0 0],'LineStyle','--');
line([1200 1200],[min(db) 10],'Color',[0 0 0],'LineStyle','--');
line([2200 2200],[min(db) 10],'Color',[0 0 0],'LineStyle','--');
title(sprintf('Emphasis and Bandpass Filter of Order %d (Fs=%d)',...
              length(r_b_full{2,3}),Fs));
xlabel('Frequency (Hz)');
ylabel('Magnitude Response (dB)');
print -dtiff -r600 emphasis_11025_normal.tif

%======================================================================%
order_multiplier = 10;
ax25;
Fs = 11025;
[H,F]=freqz(r_b_full{2,3},1,2048,Fs);
db=20*log(abs(H))/log(10);

Ht=freqz(r_b_full{2,3},1,[1200 2200],Fs)
Ht=20*log(abs(Ht))/log(10);


plot(F,db,'k-');
%get(gca)
set(gca,'YTick',[-120 -80 -40 -6 0]); 
set(gca,'XTick',[0 1200 2200 5500]); 
axis([min(F) max(F) min(db) 10]);
line([min(F) max(F)],[Ht(1) Ht(1)],'Color',[0 0 0],'LineStyle','--');
line([min(F) max(F)],[Ht(2) Ht(2)],'Color',[0 0 0],'LineStyle','--');
line([1200 1200],[min(db) 10],'Color',[0 0 0],'LineStyle','--');
line([2200 2200],[min(db) 10],'Color',[0 0 0],'LineStyle','--');
title(sprintf('Emphasis and Bandpass Filter of Order %d (Fs=%d)',...
              length(r_b_full{2,3}),Fs));
xlabel('Frequency (Hz)');
ylabel('Magnitude Response (dB)');
print -dtiff -r600 emphasis_11025_highorder.tif

%======================================================================%


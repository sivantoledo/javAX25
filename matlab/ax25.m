if ~exist('order_multiplier') 
    order_multiplier = 1
end
%  clear java 
%  javaaddpath e:\files\papers\embedded\ax25

%[x,fs,nbits]=wavread('4Z5LA_3_MAXTRAC.wav'); 
[x,fs,nbits]=wavread('4Z1PF_3_MAXTRAC.wav');
%s[x,fs,nbits]=wavread('javatest.wav');
%[x,fs,nbits]=wavread('baofeng-new.wav');
%x=xxx;
%fs=48000;

r_fs              = [9600, 12000, 11025, 16000, 22050, 24000, 44100, 48000];
r_samples_per_bit = floor(r_fs/1200);
r_nyquist         = r_fs/2;

%for r=1:length(r_fs)
%  r_b{r}=firls(r_samples_per_bit(r)-1,[0 1050 1150 2250 2350 r_nyquist(r)]/r_nyquist(r) ...
%                                ,[0    0    1    1    0     0]);
%  r_h{r}=fir1(r_samples_per_bit(r)-1,2250/r_nyquist(r));
%end

%filter_lengths = [8 16 32 64 128];
filter_lengths = [1 1];

for l=1:length(filter_lengths)
for r=1:length(r_fs)
  f = r_nyquist(r);
  %filter_length = filter_lengths(l); % max(r_samples_per_bit(r)-1,1)
  filter_length = max(order_multiplier*l*r_samples_per_bit(r)-1,1)
  fprintf(1,'// filters of length %d for Fs=%d\n',filter_length,r_fs(r));
  %r_b{r,l}=firls(filter_length,[0 1050 1150 2250 2350 f]/f ...
  %                          ,[0    0    1    1    0     0]);
  %r_b{r,l}=firls(filter_length,[0 1050 1150 2250 2350 f]/f ...
  %                          ,[0    0 0.33    1    0     0]);
  r_b_full{l,r}=firls(filter_length,[0  900 1200 2200 2500 f]/f ...
                                   ,[0    0   0.5    1    0     0]);
  r_b_none{l,r}=firls(filter_length,[0  900 1200 2200 2500 f]/f ...
                                   ,[0    0   1    1    0     0]);
  r_b_neg{l,r}=firls(filter_length,[0  900 1200 2200 2500 f]/f ...
                                   ,[0    0   1    0.5    0     0]);
  r_b_half{l,r}=firls(filter_length,[0  900 1200 2200 2500 f]/f ...
                                   ,[0    0   0.75    1    0     0]);
  %r_b{r}=firls(r_samples_per_bit(r)-1,[0  800 1000 2400 2600 f]/f ...
  %                                   ,[0    0    1    1    0    0]);
  %r_b{r}=fir1(filter_length,[ 900 2500]/f,'bandpass');
  %r_b{r} = 1;
  r_h{l,r}=fir1(filter_length,1200/f);
 end
end

r_b = r_b_full;

jf = fopen('e:\files\papers\embedded\javAX25\src\sivantoledo\ax25\Afsk1200Filters.java','w');
if jf==-1
    error 'failed to open Java source file'
end

fprintf(jf,'package sivantoledo.ax25;\n');

fprintf(jf,'public class Afsk1200Filters {\n');


fprintf(jf,'  static final public int[] sample_rates = {');
for r=1:length(r_fs); fprintf(jf,' %d',r_fs(r)); if r<length(r_fs); fprintf(jf,','); end; end; fprintf(jf,' };\n');

%fprintf(jf,'  static final public int[] filter_lengths = {');
%for r=1:length(filter_lengths); fprintf(jf,' %d',filter_lengths(r)); if r<length(filter_lengths); fprintf(jf,','); end; end; fprintf(jf,' };\n');

fprintf(jf,'  static final public int[] bit_periods = {');
for r=1:length(r_fs); fprintf(jf,' %d',r_samples_per_bit(r)); if r<length(r_fs); fprintf(jf,','); end; end; fprintf(jf,' };\n');

%=============================
tdf = r_b_full;

fprintf(jf,'  static final public float[][][] time_domain_filter_full = {\n');
for l=1:length(filter_lengths)
fprintf(jf,'   {\n');
for r=1:length(r_fs); 
    fprintf(jf,'    {');
    for k=1:length(tdf{l,r})
      fprintf(jf,' %09ef',tdf{l,r}(k)); 
      if k<length(tdf{l,r}); fprintf(jf,','); end;
    end
    fprintf(jf,' }');
    if r<length(r_fs); fprintf(jf,',\n'); else fprintf(jf,'\n'); end;
end; 
fprintf(jf,'   }');
if l<length(filter_lengths); fprintf(jf,',\n'); else fprintf(jf,'\n'); end
end
fprintf(jf,'  };\n');

tdf = r_b_none;

fprintf(jf,'  static final public float[][][] time_domain_filter_none = {\n');
for l=1:length(filter_lengths)
fprintf(jf,'   {\n');
for r=1:length(r_fs); 
    fprintf(jf,'    {');
    for k=1:length(tdf{l,r})
      fprintf(jf,' %09ef',tdf{l,r}(k)); 
      if k<length(tdf{l,r}); fprintf(jf,','); end;
    end
    fprintf(jf,' }');
    if r<length(r_fs); fprintf(jf,',\n'); else fprintf(jf,'\n'); end;
end; 
fprintf(jf,'   }');
if l<length(filter_lengths); fprintf(jf,',\n'); else fprintf(jf,'\n'); end
end
fprintf(jf,'  };\n');

%=============================

fprintf(jf,'  static final public float[][][] corr_diff_filter = {\n');
for l=1:length(filter_lengths)
fprintf(jf,'   {\n');
for r=1:length(r_fs); 
    fprintf(jf,'    {');
    for k=1:length(r_h{l,r})
      fprintf(jf,' %09ef',r_h{l,r}(k)); 
      if k<length(tdf{l,r}); fprintf(jf,','); end;
    end
    fprintf(jf,' }');
    if r<length(r_fs); fprintf(jf,',\n'); else fprintf(jf,'\n'); end;
end; 
fprintf(jf,'   }');
if l<length(filter_lengths); fprintf(jf,',\n'); else fprintf(jf,'\n'); end
end
fprintf(jf,'  };\n');
fprintf(jf,'}\n');

fclose(jf);

r = 8;

%rate = 9600;
%rate = 11025;
%rate = 8000;
%rate = 48000;
%rate = 24000;

rate = r_fs(r);

%[x,fs,nbits]=wavread('BAOFENG_TR2500_1.wav');
x=x(:,1); % in case it's stereo

decimation = fs/rate
if decimation ~= round(decimation)
    %error 'This code can only decimate by integer factors'
    %x = decimate(x,decimation);
    x = resample(x,rate,fs);
    fs = rate;
else
  if (decimation ~= 1)
      x = x(1:decimation:length(x),1);
      fs = fs/decimation;
  end
end

if rate==16000
    disp('resampling at 8k and interpolating to 16k');
    size(x)
    x = x(1:2:length(x),1);
    % now at 8k
    z(1:2:2*length(x),1) = x;
    z(2:2:2*length(x)-1,1) = 0.5*(x(1:length(x)-1,1)+x(2:length(x),1) );
    %[x,interp_filter] = interp(x,2,4,0.5);
    %interp_filter
    x = z;
    size(x)
end

%plot(z)   
%error('xxx')

length(x)
fs
samples_per_bit = floor(fs/1200);
%[samples_per_bit fs/1200]

td_filter_order = samples_per_bit-1;
corrdiff_filter_order = samples_per_bit-1;

%[x,fs,nbits]=wavread('4Z1PF_3_MAXTRAC.wav'); 
%[x,fs,nbits]=wavread('4Z1PF_3_TR2500.wav'); 
y=x; % just for testing
nsamples = length(x);

%f1=1050;f2=1150;w1=f1/(fs/2);w2=f2/(fs/2);b=fir1(512,[w1,w2]);
%sy=filter(b,1,x);
%f=900;w=f/(fs/2);highpass=fir1(38,w,'high');
%x = filter(highpass,1,x);

%f1=1150;f2=1250;w1=f1/(fs/2);w2=f2/(fs/2);b1=fir1(samples_per_bit-1,[w1,w2]);
%x=filter(b1,1,x);
%f1=2150;f2=2250;w1=f1/(fs/2);w2=f2/(fs/2);b2=fir1(samples_per_bit-1,[w1,w2]);
%x=filter(b2,1,x);

%f1=1150;f2=2250;w1=f1/(fs/2);w2=f2/(fs/2);b1=fir1(td_filter_order,[w1,w2],'bandpass');
%f1=1250;f2=2150;w1=f1/(fs/2);w2=f2/(fs/2);b2=fir1(td_filter_order,[w1,w2],'stop');
%size(b1)
%size(b2)
%x=filter(b1.*b2,1,x);
%x=filter(b1,1,x);

%nyquist = fs/2;
%b=firls(td_filter_order,[0 1050 1150 2250 2350 nyquist]/nyquist ...
%                       ,[0    0    1    1    0     0]);
%x=filter(b,1,x);

filter_index = 2;
x = filter(r_b{filter_index,r},1,x);

%f=1300;w=f/(fs/2);h=fir1(corrdiff_filter_order,w);
h = r_h{filter_index,r};


t=0:2*pi/fs:2*pi*nsamples/fs'; t=t(1:nsamples);
t=0:2*pi/fs:2*pi*nsamples/fs'; t=t(1:nsamples);
f0=exp(i*1200*t);
f1=exp(i*2200*t);

%b1
%b2
%h
%f0
%f1
%return;

c0=f0'.*x;
c1=f1'.*x;

z0 = zeros(nsamples,1);
z1 = zeros(nsamples,1);
diff = zeros(nsamples,1);
fdiff = zeros(nsamples,1); % filtered
d  = zeros(nsamples,1);

%s = x.^2; % 
%s0 = c0.^2;
%s1 = c1.^2;

%periods = nan*zeros(nsamples,1); % symbols energy
%dcd = zeros(nsamples,1); % symbols energy
%gd  = zeros(nsamples,1); 
%bd  = zeros(nsamples,1); 

%threshold = 0;

last_transition = 0;
%good_periods_counter = 0;
%bad_periods_counter = 0;
timing_threshold = samples_per_bit / 4;

%bs = []; % bit stream
byte = 0;
bitcount = 0;
%mask=0;
  
%sample_points = zeros(nsamples,1);
%sample_point = 0;
%stuffcount  = 0;
%data = 0;
%databits = 0;

state = 0; % waiting for a packet

%afsk1200 = sivantoledo.ax25.Afsk1200(fs);

%for k=1:length(h)
%    fprintf('%09ef,\n',b2(k));
%end
%return

for j=1:nsamples
  %afsk1200.addSamples([y(j)],1);  
  %[f0(j) f1(j) j 11*samples_per_bit]
  
  if j < samples_per_bit || j < length(h)
      continue;
  end
      
  period = j-samples_per_bit+1:j;
  
  z0(j) = abs(sum(c0(period)));
  z1(j) = abs(sum(c1(period)));
  diff(j)  = z0(j)-z1(j);
  
  fdiff(j) = h*diff(j-length(h)+1:j); % this introduces a delay but from here on we only care about 
                             % zero crossings of fdiff.

  % disp(fdiff(j));
                             
  d(j) = fdiff(j) > 0;
  
  %dcd(j) = dcd(j-1); % for now; we may flip it
  if d(j)~=d(j-1)
      p = j - last_transition;
      %periods(j) = p;
      last_transition = j;
      
      % how many bits?
      
      bits = round(p / samples_per_bit);
      %fprintf('  %04f %d %02x %d\n',p/samples_per_bit,bits,byte,bitcount);
      
      if bits==0 || bits>7
        state=0; % looking for a flag
        continue;
      end
       
      %if dcd(j)==1
        if bits==7
            disp('flag');
            data = 0;
            databits = 0;
            byte = 0;
            bitcount = 0;
          if true
          switch state
              case 0
                  state=1;
              case 1
                  continue;
              case 2
                  %if packet.terminate()
                  %    fprintf(1,'Matlab decoded:\n');
                  %    packet
                  %    fprintf(1,'Matlab decoded end\n');
                  %else
                  %    disp('bad packet (or no packet)');
                  %end
                  disp('done with this packet');
                  state=1;
              otherwise
                  disp('flag in state other than 0, 1, 2');
          end
          end
          %if state==0; state=1; end; % ready to start a packet
          %if state==2; packet.terminate(); state=1; end
        else
          if true
          switch state
              case 0
                  continue; % continue to search for a flag
              case 1
                  state=2; % start a packet
                  %packet=sivantoledo.ax25.Packet();
              case 2
                  ; % fprintf('reading %d bits j=%d\n',bits,j);
          end
          end
          %if state==0 continue;end;
          %if state==1; state=2; packet=sivantoledo.ax25.Packet(); disp('starting'); end
          for k=1:bits-1
             bitcount = bitcount+1;
             byte = bitshift(byte,-1);
             byte = byte+128; % turn on the least-significant bit
             if (bitcount == 8)
                  fprintf('> %02x %c %c\n',byte,char(byte),char(bitshift(byte,-1)));
                  %if packet.addByte(byte) == false
                  %    state=0; % looks like a packet, but too long
                  %end
                  byte=0;
                  bitcount=0;
              end
          end
          if bits-1~=5 % the zero we just saw (the transition) was not stuffed
              bitcount = bitcount+1;
              byte = bitshift(byte,-1);
              % byte = byte+1; % turn on the least-significant bit
              if (bitcount == 8)
                  fprintf(1,'> %02x %c %c\n',byte,char(byte),char(bitshift(byte,-1)));
                  %state
                  %packet.addByte(byte);
                  %if packet.addByte(byte) == false
                  %    state=0; % looks like a packet, but too long
                  %end
                  byte=0;
                  bitcount=0;
              end
          else
              fprintf(1,'stuffed bit\n');
          end
        end
      %end % if dcd
  end % if d(j) ~= d(j-1)
  
end % of j loop



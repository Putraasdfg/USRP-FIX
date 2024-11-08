 function SimParams = sdruQPSKTransmitterSLInit(platform, useCodegen, isHDLCompatible)
%   Copyright 2023 The MathWorks, Inc.

%% General simulation parameters

if isHDLCompatible
    SimParams.Rsym = 0.5e6;          % Symbol rate in Hertz
                                   % If HDL compatible, code will not be optimized in performance
else
    if useCodegen
        SimParams.Rsym = 5e6;      % Symbol rate in codegen path
    else
        SimParams.Rsym = 2.5e6;
    end
end

SimParams.ModulationOrder = 4;      % QPSK alphabet size
SimParams.Interpolation = 2;        % Interpolation factor
SimParams.Decimation = 1;           % Decimation factor
SimParams.Tsym = 1/SimParams.Rsym;  % Symbol time in sec
SimParams.Fs   = SimParams.Rsym * SimParams.Interpolation; % Sample rate

%% Frame Specifications
% [BarkerCode*2 | 'Hello world 000\n' | 'Hello world 001\n' ...];
SimParams.BarkerCode      = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];     % Bipolar Barker Code
SimParams.BarkerLength    = length(SimParams.BarkerCode);
SimParams.HeaderLength    = SimParams.BarkerLength * 2;                   % Duplicate 2 Barker codes to be as a header
SimParams.Message         = 'Telkom University Purwokerto awalnya merupakan bagian dari institusi pendidikan tinggi di bawah Yayasan Pendidikan Telkom. Berawal dari beberapa sekolah tinggi yang didirikan untuk memenuhi kebutuhan industri telekomunikasi di Indonesia, Telkom University berkembang menjadi universitas berstandar internasional. kampus ini adalah cabang yang mendukung misi utama Telkom University dalam menyediakan pendidikan berkualitas. Fokusnya adalah pada teknologi, informasi, dan komunikasi di era digital. Telkom University Purwokerto juga menawarkan program-program yang relevan dengan kebutuhan industri saat ini. Dengan dosen berkualitas Telkom University Purwokerto berupaya menjadi pusat pendidikan unggulan. Telkom University Purwokerto terus berkembang dan berkontribusi pada pengembangan SDM unggul di bidang teknologi dan bisnis';
SimParams.MessageLength   = length(SimParams.Message) + 5;                % 'Hello world 000\n'...
SimParams.NumberOfMessage = 1;                                            % Number of messages in a frame
SimParams.PayloadLength   = SimParams.NumberOfMessage * SimParams.MessageLength * 7; % 7 bits per characters
SimParams.FrameSize       = (SimParams.HeaderLength + SimParams.PayloadLength) ...
    / log2(SimParams.ModulationOrder);                                    % Frame size in symbols
SimParams.FrameTime       = SimParams.Tsym*SimParams.FrameSize;

%% Tx parameters
SimParams.RolloffFactor     = 0.5;                                        % Rolloff Factor of Raised Cosine Filter
SimParams.ScramblerBase     = 2;
SimParams.ScramblerPolynomial           = [1 1 1 0 1];
SimParams.ScramblerInitialConditions    = [0 0 0 0];
SimParams.RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)

%% Message generation
msgSet = zeros(100 * SimParams.MessageLength, 1); 
for msgCnt = 0 : 99
    msgSet(msgCnt * SimParams.MessageLength + (1 : SimParams.MessageLength)) = ...
        sprintf('%s %03d\n', SimParams.Message, msgCnt);
end
bits = de2bi(msgSet, 7, 'left-msb')';
SimParams.MessageBits = bits(:);

%% USRP transmitter parameters
switch platform
  case {'B200','B210'}
    SimParams.MasterClockRate = 20e6;           % Hz
  case {'X300','X310'}
    SimParams.MasterClockRate = 200e6;          % Hz
  case {'N300','N310'}
    SimParams.MasterClockRate = 125e6;          % Hz
  case {'N320/N321'}
    SimParams.MasterClockRate = 200e6;          % Hz
  case {'N200/N210/USRP2'}
    SimParams.MasterClockRate = 100e6;          % Hz
  otherwise
    error(message('sdru:examples:UnsupportedPlatform', ...
      platform))
end
SimParams.USRPCenterFrequency       = 900e6;
SimParams.USRPGain                  = 1;
SimParams.USRPFrontEndSampleRate    = SimParams.Rsym * 2; % Nyquist sampling theorem
SimParams.USRPInterpolationFactor   = SimParams.MasterClockRate/SimParams.USRPFrontEndSampleRate;
SimParams.USRPFrameLength           = SimParams.Interpolation * SimParams.FrameSize;

% Experiment Parameters
SimParams.USRPFrameTime = SimParams.USRPFrameLength/SimParams.USRPFrontEndSampleRate;
SimParams.StopTime = 1000;
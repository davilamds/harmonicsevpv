tic; clear; clc; close all;clear all;
%% **********************************************************************************************************
% Basic Definitions & Input Data
input.mydir = pwd; %>>>>>>Set Directoty
input.input_path = [input.mydir '\Input_data' ]; %>>>>>>Path of the folder where all input data are
input.name_circuit = 'circuit'; %>>>>>>Specify the name of the circuit to assess
%input.num_MC_Simul = 1; %>>>>>>Number of MC repetitions
steps=144
input.time_steps = steps; %>>>>>>Steps of the daily simulation (1 day = 1440 steps of 1min)
%% Start up the DSS
DSSObj = actxserver('OpenDSSEngine.DSS');                       %initialization the DSS Object
DSSText = DSSObj.Text;                                          %Define the text interface
DSSText.Command = 'clear';                                      %Clear previous session
DSSText.Command = ['Compile (' input.input_path '\' input.name_circuit '\Master.dss)'];
DSSCircuit = DSSObj.ActiveCircuit; %>>>>>>Set up the Circuit
DSSSolution = DSSCircuit.Solution; %>>>>>>Set up the Solution
ControlQueue = DSSCircuit.CtrlQueue; %>>>>>>Set up the Control
DSSLoad     = DSSCircuit.Loads;
DSSObj.AllowForms = 0; %>>>>>>Avoids getting OpenDSS messages

%% Place Monitors in every Line
line_data = importdata([input.input_path '\' input.name_circuit '\Lines.txt']);
for i_temp = 1:size(line_data,1)
    var_temp = line_data{i_temp,1};
    var_temp = strsplit(var_temp,' ');
    var_temp1 = strsplit(var_temp{1,2},'.');
    DSSText.Command = ['new monitor.' var_temp1{1,2} ' element=' var_temp{1,2} ' terminal=1 mode=1 ppolar=no'];
end
clear var_temp var_temp1 i_temp line_data

%% Place Monitors in every Tranformer
trafo_data = importdata([input.input_path '\' input.name_circuit '\Transformers.txt']);
i_temp = 1:size(trafo_data,1);
var_temp = trafo_data{i_temp,1};
var_temp = strsplit(var_temp,' '); %-------cambiar split por strsplit-----
var_temp1 = strsplit(var_temp{1,2},'.');
DSSText.Command = ['new monitor.' var_temp1{1,2} ' element=' var_temp{1,2} ' terminal=1 mode=1 ppolar=no'];
clear var_temp var_temp1 i_temp trafo_data

%tensiones en puntos de medicion de las cargas
DSSText.Command = 'new monitor.load20 element=load.load20 terminal=1 mode=0';
DSSText.Command = 'new monitor.load32 element=load.load32 terminal=1 mode=0';
DSSText.Command = 'new monitor.load53 element=load.load53 terminal=1 mode=0';
%DSSText.Command = 'new monitor.load1 element=line.line33 terminal=1 mode=0';
 
clear var_temp var_temp1 i_temp line_data
%% *********************************************************************************************************

% SIMULATION CONTROL

enable_pvsystems=2; %0 disabled 1 enabled (case 1) 2 enabled (case 2)
enable_vehicles=1;

if enable_vehicles==1
    DSSText.Command = 'Redirect vehicles.txt';
end

if enable_pvsystems==1
    DSSText.Command = 'Redirect Photovoltaic.txt';
end

if enable_pvsystems==2
    DSSText.Command = 'Redirect Photovoltaic2.txt';
end

voltaje50=zeros(steps,1);
voltaje150=zeros(steps,1);
voltaje250=zeros(steps,1);
voltaje350=zeros(steps,1);
voltaje450=zeros(steps,1);
voltaje550=zeros(steps,1);

corriente50=zeros(steps,1);
corriente150=zeros(steps,1);
corriente250=zeros(steps,1);
corriente350=zeros(steps,1);
corriente450=zeros(steps,1);
corriente550=zeros(steps,1);


potencia_activa1=zeros(steps,1);
potencia_reactiva1=zeros(steps,1);
potencia_activa2=zeros(steps,1);
potencia_reactiva2=zeros(steps,1);
potencia_activa3=zeros(steps,1);
potencia_reactiva3=zeros(steps,1);

DSSText.Command = 'Set ControlMode = time'; %>>>>>>Defines the control mode
%DSSText.Command = 'Reset'; %>>>>>>Resets all energy meters and monitors
%DSSText.Command = 'Set Mode = daily stepsize = 1m number = 1'; %>>>>>>Defines simulatins parameters
%DSSText.Command = 'Set Mode=harmonicT stepsize = 1h';
    for time_simulation = 1:input.time_steps; %>>>>>>Starts time-series power flow
        %DSSText.Command = 'Set ControlMode = time';
        t = sprintf('Set Mode=daily stepsize = 10m number = %f',time_simulation);
        DSSText.Command = t;
        DSSSolution.Solve; %>>>>>>Solves power flow
        t = sprintf('Set Mode=harmonicT stepsize = 10m number = %f',time_simulation)';
        DSSText.Command = t;
        DSSSolution.Solve; %>>>>>>Solves power flow
        voltaje_cliente_1 = ExtractMonitorData(DSSCircuit,'load20');
        voltaje50(time_simulation,1)=voltaje_cliente_1(1,3);
        voltaje150(time_simulation,1)=voltaje_cliente_1(2,3);
        voltaje250(time_simulation,1)=voltaje_cliente_1(3,3);
        voltaje350(time_simulation,1)=voltaje_cliente_1(4,3);
        voltaje450(time_simulation,1)=voltaje_cliente_1(5,3);
        voltaje550(time_simulation,1)=voltaje_cliente_1(6,3);
        
        corriente50(time_simulation,1)=voltaje_cliente_1(1,7);
        corriente150(time_simulation,1)=voltaje_cliente_1(2,7);
        corriente250(time_simulation,1)=voltaje_cliente_1(3,7);
        corriente350(time_simulation,1)=voltaje_cliente_1(4,7);
        corriente450(time_simulation,1)=voltaje_cliente_1(5,7);
        corriente550(time_simulation,1)=voltaje_cliente_1(6,7);
        
        potencia_lado_alta = ExtractMonitorData(DSSCircuit,'TR1');
        potencia_activa1(time_simulation,1)=potencia_lado_alta(1,3);
        potencia_reactiva1(time_simulation,1)=potencia_lado_alta(1,4);
        potencia_activa2(time_simulation,1)=potencia_lado_alta(1,5);
        potencia_reactiva2(time_simulation,1)=potencia_lado_alta(1,6);
        potencia_activa3(time_simulation,1)=potencia_lado_alta(1,7);
        potencia_reactiva3(time_simulation,1)=potencia_lado_alta(1,8);
        %if you do control, here it comes
    end
 %DSSText.Command    =   'show monitor MPCC';
 DSSText.Command    =   'show monitor TR1';
    
 voltajef=[voltaje50 voltaje150 voltaje250 voltaje350 voltaje450 voltaje550];
 corrientef=[corriente50 corriente150 corriente250 corriente350 corriente450 corriente550];
 potencia_activaf=[potencia_activa1 potencia_activa2 potencia_activa3];
 potencia_reactivaf=[potencia_reactiva1 potencia_reactiva2 potencia_reactiva3];
 
 %Potencia de cada fase en el lado de alta del tranformador de
    %subestacion
    DSSCircuit.Meters.Name = 'Trafo_subestacion';
    potencia_lado_alta = ExtractMonitorData(DSSCircuit,'TR1');

    
    %Tensiones y corrientes en el Cliente 1
     DSSCircuit.Meters.Name = 'load1';
     voltaje_cliente_1 = ExtractMonitorData(DSSCircuit,'load20');
     
     %Tensiones y corrientes en el Cliente 2
     DSSCircuit.Meters.Name = 'cliente_2';
     voltaje_cliente_2 = ExtractMonitorData(DSSCircuit,'load32');
     
     %Tensiones y corrientes en el Cliente 3
     DSSCircuit.Meters.Name = 'cliente_3';
     voltaje_cliente_3 = ExtractMonitorData(DSSCircuit,'load53');

    
    %% POTENCIA PICO.
    %PT=potencia_lado_alta(:,3)+potencia_lado_alta(:,5)+potencia_lado_alta(:,7);
    %QT=potencia_lado_alta(:,4)+potencia_lado_alta(:,6)+potencia_lado_alta(:,8);
    %ST=sqrt(PT.^2+QT.^2);
    %for x = 1:1440
    %    if ST(x) == max(ST);
    %        POS_MAX=x;
    %    end
    %end
    
    %ST_MAX = ST(POS_MAX);
    %HORA_PICO = POS_MAX/60;
    %disp('Max Power MAX[MVA] es:')
    %disp(ST_MAX)
    %disp('Max Power time:')
    %disp(HORA_PICO)
    
    
    %% GRAFICA DE POTENCIAS
     %TIEMPO = 1/60:1/60:24;
     TIEMPO = 1/6:1/6:24;
     g1 = subplot (2,1,1);
     plot(g1, TIEMPO ,potencia_activaf(:,1));
     hold on
     plot(g1, TIEMPO, potencia_activaf(:,2), 'b');
     plot(g1, TIEMPO, potencia_activaf(:,3), 'r');
     title(g1,'Substation transformer power curve')
     xlabel(g1,'Time [Hour]')
     ylabel(g1,'Power [KW]')
     xlim([0 24]) 
     legend('Phase A','Phase B','Phase C')
     g1.XTick = [0:24];
     grid on
    
    potencia=potencia_activaf(:,1)+potencia_activaf(:,2)+potencia_activaf(:,3)
    g2 = subplot (2,1,2);
    plot(g2, TIEMPO ,potencia');
    title(g2,'Substation transformer power curve (total)')
    xlabel(g2,'Time [Hour]')
    ylabel(g2,'Power [KW]')
    xlim([0 24])
    g2.XTick = [0:24];
    grid on
    hold off
    
%     %% GRAFIA DE VOLTAJES 
%     figure;
%     plot(TIEMPO ,voltaje_cliente_1(:,3));
%     hold on
%     plot(TIEMPO ,voltaje_cliente_2(:,3), 'b');
%     plot(TIEMPO ,voltaje_cliente_3(:,3), 'r');
%     title('Load Voltages')
%     xlabel('Time [Hour]')
%     ylabel('Voltage [V]')
%     xlim([0 24]) 
%     legend('Load 1','Load 2','Load 3')
%     hold off
%     XTick = [0:24];
%     grid on
%     
%  clear time_simulation g1 g2 g3 g4 g5 g6

    %% GRAFIA DE VOLTAJES 
    figure;
    plot(TIEMPO ,voltajef(:,1));
    hold on
    
    title('Load Voltages')
    xlabel('Time [Hour]')
    ylabel('Voltage [V]')
    xlim([0 24]) 
    legend('Load 349')
    hold off
    XTick = [0:24];
    grid on
    
    figure;
    plot(TIEMPO ,corrientef(:,1));
    hold on
    
    title('Load Voltages')
    xlabel('Time [Hour]')
    ylabel('Voltage [V]')
    xlim([0 24]) 
    legend('Load 349')
    hold off
    XTick = [0:24];
    grid on
    
 clear time_simulation g1 g2 g3 g4 g5 g6

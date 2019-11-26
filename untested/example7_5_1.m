% 
% written by:
% Ernest Chan
%
% Author of ?Quantitative Trading: 
% How to Start Your Own Algorithmic Trading Business?
%
% ernest@epchan.com
% www.epchan.com

clear; % make sure previously defined variables are erased.
 
%[num, txt]=xlsread('GLD'); % read a spreadsheet named "GLD.xls" into MATLAB. 
 
%tday1=txt(2:end, 1); % the first column (starting from the second row) is the trading days in format mm/dd/yyyy.
 
%tday1=datestr(datenum(tday1, 'mm/dd/yyyy'), 'yyyymmdd'); % convert the format into yyyymmdd.
 
%tday1=str2double(cellstr(tday1)); % convert the date strings first into cell arrays and then into numeric format.
 
%adjcls1=num(:, end); % the last column contains the adjusted close prices.

[tday1, adjcls1]=getTday('GLD');

%[num2, txt2]=xlsread('GDX'); % read a spreadsheet named "GDX.xls" into MATLAB. 
 
%tday2=txt2(2:end, 1); % the first column (starting from the second row) is the trading days in format mm/dd/yyyy.
 
%tday2=datestr(datenum(tday2, 'mm/dd/yyyy'), 'yyyymmdd'); % convert the format into yyyymmdd.
 
%tday2=str2double(cellstr(tday2)); % convert the date strings first into cell arrays and then into numeric format.

%adjcls2=num2(:, end);

[tday2, adjcls2]=getTday('GDX');

tday=union(tday1, tday2); % find all the days when either GLD or GDX has data.

[foo idx idx1]=intersect(tday, tday1);

adjcls=NaN(length(tday), 2); % combining the two price series
%tmp=[length(tday), 2];
%tmp(1:length(tday),1:2)=NaN;
%adjcls=tmp;

adjcls(idx, 1)=adjcls1(idx1);% adjcls=NaN(length(tday), 3);

[foo idx idx2]=intersect(tday, tday2);

adjcls(idx, 2)=adjcls2(idx2);

baddata=find(any(~isfinite(adjcls), 2)); % days where any one price is missing

tday(baddata)=[];

adjcls(baddata, :)=[];

vnames=strvcat('GLD', 'GDX');

res=cadf(adjcls(:, 1), adjcls(:, 2), 0, 1); % run cointegration check using augmented Dickey-Fuller test

prt(res, vnames); 

% Output from cadf function:

%  Augmented DF test for co-integration variables:                        GLD,GDX  
% CADF t-statistic        # of lags   AR(1) estimate 
%      -3.35698533                1        -0.060892 
% 
%    1% Crit Value    5% Crit Value   10% Crit Value 
%           -3.819           -3.343           -3.042 

% The t-statistic of -3.36 which is in between the 1% Crit Value of -3.819
% and the 5% Crit Value of -3.343 means that there is a better than 95%
% probability that these 2 time series are cointegrated.

results=ols(adjcls(:, 1), adjcls(:, 2)); 

hedgeRatio=results.beta
z=results.resid;

% A hedgeRatio of 1.6766 was found. I.e. GLD=1.6766*GDX + z, where z can be interpreted as the
% spread GLD-1.6766*GDX and should be stationary.

plot(z); % This should produce a chart similar to Figure 7.4.

prevz=backshift(1, z); % z at a previous time-step
dz=z-prevz;
dz(1)=[];
prevz(1)=[];
results=ols(dz, prevz-mean(prevz)); % assumes dz=theta*(z-mean(z))dt+w, where w is error term
theta=results.beta;

halflife=-log(2)/theta

% halflife =
% 
%    10.0037
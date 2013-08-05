% DN_SimpleFit
% 
% Fits different distributions or simple time-series models to the time series
% using 'fit' function from Matlab's Curve Fitting Toolbox.
% 
% The distribution of time-series values is estimated using either a
% kernel-smoothed density via the Matlab function ksdensity with the default
% width parameter, or by a histogram with a specified number of bins, nbins.
% 
% INPUTS:
% x, the input time series
% 
% dmodel, the model to fit:
%       (I) distribution models:
%           (i) 'gauss1'
%           (ii) 'gauss2'
%           (iii) 'exp1'
%           (iv) 'power1'
%       (II) simple time-series models:
%           (i) 'sin1'
%           (ii) 'sin2'
%           (iii) 'sin3'
%           (iv) 'fourier1'
%           (v) 'fourier2'
%           (vi) 'fourier3'
% 
% nbins, the number of bins for a histogram-estimate of the distribution of
%       time-series values. If nbins = 0, uses ksdensity instead of histogram.
% 
% Outputs are the goodness of fifit, R^2, rootmean square error, the
% autocorrelation of the residuals, and a runs test on the residuals.
% 

function out = DN_SimpleFit(x,dmodel,nbins)
% Ben Fulcher, 2009

%% Fit the model
% Two cases: distribution fits and fits on the data
Distmods = {'gauss1','gauss2','exp1','power1'}; % valid distribution models
TSmods = {'sin1','sin2','sin3','fourier1','fourier2','fourier3'}; % valid time series models

if any(strcmp(Distmods,dmodel)); % valid DISTRIBUTION model name
    if nargin < 3 || isempty(nbins); % haven't specified nbins
        nbin = 10; % use 10 bins by default
    end
    if nbins == 0; % use ksdensity instead of a histogram
        [dny, dnx] = ksdensity(x);
    else
        [dny, dnx] = hist(x,nbins);
    end
    if size(dnx,2) > size(dnx,1); dnx = dnx'; dny = dny'; end % must be column vectors
    
    try
        [cfun, gof, output] = fit(dnx,dny,dmodel); % fit the model
	catch emsg % this model can't even be fitted OR license problem...
        if strcmp(emsg.message,'NaN computed by model function.') ...
                || strcmp(emsg.message,'Inf computed by model function.') ...
                || strcmp(emsg.message,'Power functions cannot be fit to non-positive xdata.') ...
                || strcmp(emsg.identifier,'curvefit:fit:nanComputed')
            fprintf(1,'The model, %s, failed for this data -- returning NaNs for all fitting outputs\n',dmodel);
            out = NaN; return
        else
            error('DN_SimpleFit(x,%s,%u): Unexpected error fitting %s to the data distribution',dmodel,nbins,dmodel)
        end
	end
elseif any(strcmp(TSmods,dmodel)); % valid TIME SERIES model name
    if size(x,2) > size(x,1)
        x = x';
    end % x must be a column vector
    t = (1:length(x))'; % Time variable for equal sampling of the univariate time series
    try
        [cfun, gof, output] = fit(t,x,dmodel); % fit the model
	catch emsg % this model can't even be fitted OR license problem
        if strcmp(emsg.message,'NaN computed by model function.') || strcmp(emsg.message,'Inf computed by model function.')
            fprintf(1,'The model %s failed for this data -- returning NaNs for all fitting outputs\n',dmodel);
            out = NaN; return
        else
            error('DN_SimpleFit(x,%s,%u): Unexpected error fitting ''%s'' to the time series',dmoel,nbins,dmodel)
        end
	end
else
    error('Invalid distribution or time-series model ''%s'' specified',dmodel);
end

%% Prepare the Output
out.r2 = gof.rsquare; % rsquared
out.adjr2 = gof.adjrsquare; % degrees of freedom-adjusted rsqured
out.rmse = gof.rmse;  % root mean square error
out.resAC1 = CO_AutoCorr(output.residuals,1); % autocorrelation of residuals at lag 1
out.resAC2 = CO_AutoCorr(output.residuals,2); % autocorrelation of residuals at lag 2
out.resruns = HT_HypothesisTests(output.residuals,'runstest'); % runs test on residuals -- outputs p-value

end